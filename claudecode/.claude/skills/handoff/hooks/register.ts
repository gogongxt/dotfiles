import type { EngineInterface, Register } from 'claude-code'

// Where the note lands. One file per session, so a second /handoff in the same
// session overwrites its own note instead of piling up.
const HANDOFF_DIR = '/tmp'

// How many further turns to keep watching for the note before giving up. The
// writing turn is normally the very next one; the slack is for a turn the model
// spends asking a question first.
const WATCH_TURNS = 6

// Long enough that the turn the hook is holding has ended, short enough that no
// one notices. Compaction and prompt submission are both refused while a turn
// runs, and a hook always runs inside one, so they are handed to a timer.
const AFTER_TURN_MS = 400

type Watch = {
  path: string
  // The note's last-write time when /handoff ran, so a leftover from an earlier
  // handoff in this same session is not mistaken for a fresh write. -1 when the
  // file is not there yet.
  seenMtime: number
  turnsLeft: number
}

let watch: Watch | null = null

const notePath = (id: string) => `${HANDOFF_DIR}/claude-handoff-${id}.md`

// The note's last-write time, or -1 when there is none. `stat` rejects on a
// missing path, so absence is the catch.
const mtimeOf = async ($: EngineInterface, path: string): Promise<number> => {
  try {
    return (await $.fs.stat(path)).mtimeMs
  } catch {
    return -1
  }
}

const asking =
  (path: string, focus: string) =>
  `Before your context is compacted, write a handoff note to ${path} so you can ` +
  'resume this work from it afterwards. Use the Write tool. Cover, in order:\n\n' +
  '1. Goal — what the person actually asked for, in their terms.\n' +
  '2. State — what is done, what is in progress, what is left.\n' +
  '3. Files that matter — absolute paths, and what each is for.\n' +
  '4. Decisions already made, and why, so the next you does not relitigate them.\n' +
  '5. Next action — concrete enough to start without thinking.\n' +
  '6. Open questions or blockers.\n' +
  '7. Every skill this session was invoked through, by name, and what each was for.\n' +
  (focus ? `\nThe person added this focus: ${focus}\n` : '') +
  '\nWrite the file now. Do not summarize your work in your reply; just write it and say it is saved.'

// Compact the conversation, then start the next turn on the note. Compaction
// only runs between turns, so this is reached from a timer, never a hook body.
const resumeFrom = ($: EngineInterface, path: string): void => {
  const attempt = (left: number): void => {
    $.clock.after(AFTER_TURN_MS, () => {
      void (async () => {
        let skip: string | undefined
        try {
          const result = await $.session.compact({
            instructions:
              `Resume from the handoff note at ${path}. Keep the note's path, the goal, ` +
              'the state, the decisions and the next action. Drop the exploratory reads ' +
              'and the back-and-forth that led here.',
          })
          skip = 'skip' in result ? result.skip : undefined
        } catch (err) {
          // Only a turn still running is worth waiting out; anything else (a
          // veto, DISABLE_COMPACT, a headless session) is permanent.
          if (left > 0 && String(err).includes('a turn is running')) {
            attempt(left - 1)
            return
          }
          $.ui.log(`handoff: compaction failed: ${String(err)}`, { to: 'debug' })
          $.ui.toast(`Handoff: could not compact — the note is saved at ${path}.`)
          return
        }

        if (skip !== undefined) {
          $.ui.log(`handoff: compaction skipped: ${skip}`, { to: 'debug' })
          $.ui.toast(`Handoff: compaction skipped (${skip}). Note saved at ${path}.`)
          return
        }

        void $.prompt
          .submit({
            text:
              `Read ${path} and continue the work it describes. Follow its next action; ` +
              'do not re-derive what it already records.',
          })
          .catch((err: unknown) =>
            $.ui.log(`handoff: resume prompt refused: ${String(err)}`, { to: 'debug' }),
          )
        $.ui.toast('Handoff complete — resumed from the note.')
      })()
    })
  }

  attempt(20)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    try {
      await $.command.register({
        name: 'handoff',
        description: 'Save the goal and progress to a file, compact, and resume from it',
        argumentHint: '[optional focus]',
      })
    } catch (err) {
      $.ui.log(`handoff: could not register /handoff: ${String(err)}`, { to: 'debug' })
      $.ui.toast('Handoff: /handoff could not be registered (name taken?).')
    }
    return next(e)
  })

  // The person runs /handoff. This hook answers the command itself and starts
  // the writing turn from a timer: a hook holds its own turn, so a prompt
  // submitted here would wait on it forever.
  on('command.run', { command: 'handoff' }, async ($, e) => {
    const path = notePath(await $.session.id())
    const focus = e.args.trim()

    watch = { path, seenMtime: await mtimeOf($, path), turnsLeft: WATCH_TURNS }

    $.clock.after(AFTER_TURN_MS, () => {
      void $.prompt
        .submit({ text: asking(path, focus) })
        .catch((err: unknown) =>
          $.ui.log(`handoff: writing prompt refused: ${String(err)}`, { to: 'debug' }),
        )
    })

    return { text: `Handoff: writing ${path}, then compacting and resuming.` }
  })

  // Each turn's end, while a handoff is in flight. The note being rewritten is
  // the signal; there is no token for the model to remember to print.
  on('turn.complete', async ($, e, next) => {
    if (watch === null || e.agentId !== undefined) return next(e)

    const current = watch

    if ((await mtimeOf($, current.path)) > current.seenMtime) {
      watch = null
      resumeFrom($, current.path)
      return next(e)
    }

    current.turnsLeft -= 1
    if (current.turnsLeft <= 0) {
      watch = null
      $.ui.toast(`Handoff: no note appeared at ${current.path}; nothing was compacted.`)
    }

    return next(e)
  })
}
