import type { CommandRunInput, On } from 'claude-code'
import { expect, mock, test } from 'claude-code/testing'

// The engine sits beneath the plugin in these tests: every `on` here answers a
// call the plugin makes, or raises an event the plugin hooks. A hook registered
// by the test returns the call's result directly.

const SESSION_ID = 'abc123'
const NOTE = `/tmp/claude-handoff-${SESSION_ID}.md`

// The input `command.run` carries as the engine raises it (the plugin's own call
// takes less, but the test's `$` is the engine's).
const runHandoff = (args = ''): CommandRunInput => ({
  command: 'handoff',
  args,
  origin: { kind: 'composer' },
  presentation: { isFullscreen: false, columns: 100 },
})

function harness(
  opts: { mtime?: () => number; compact?: (e: unknown) => unknown } = {},
) {
  const submitted: string[] = []
  const compacted: { instructions?: string }[] = []
  const logged: string[] = []
  let compactResult: unknown = { messages: [{ role: 'user', text: 'summary', toolUses: [] }] }

  const wire = (on: On) => {
    // A call on `$` (an "op") answers `{ value }`; an event answers its own result.
    on('command.register', () => ({ value: { command: 'handoff' } }))
    on('session.id', () => ({ value: SESSION_ID }))
    on('session.compact', (_$, e) => {
      compacted.push(e)
      return (opts.compact ? opts.compact(e) : compactResult) as never
    })
    on('prompt.submit', (_$, e) => {
      submitted.push(e.text)
      return { text: e.text }
    })
    on('fs.stat', (_$, e) => {
      const mtime = opts.mtime ? opts.mtime() : -1
      if (mtime < 0) throw new Error('ENOENT')
      return { value: { kind: 'file', size: 100, mtimeMs: mtime, isLink: false } }
    })
    on('ui.log', (_$, e) => {
      logged.push(e.text)
      return { value: undefined }
    })
    on('ui.toast', () => ({ value: undefined }))
    on('session.start', (_, e) => ({ cwd: e.cwd }))
    on('turn.complete', () => ({ text: '' }))
  }

  return {
    wire,
    submitted,
    compacted,
    logged,
    setCompactResult: (r: unknown) => {
      compactResult = r
    },
  }
}

test('a write to the note compacts and then resumes', async ($, on) => {
  let mtime = -1
  const h = harness({ mtime: () => mtime })
  h.wire(on)
  const clock = mock.clock(on)

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })

  // The person runs /handoff. The writing prompt leaves on a timer.
  const run = await $.command.run(runHandoff())
  expect(run.text).toContain(NOTE)
  expect(h.submitted).toHaveLength(0)
  await clock.advance(600)
  expect(h.submitted).toHaveLength(1)
  expect(h.submitted[0]).toContain(NOTE)

  // The model writes the note, and the turn ends.
  mtime = 1000
  await $.turn.complete({
    answer: 'Saved.',
    reason: 'answer',
    durationMs: 1,
    isAborted: false,
    turnId: 't1',
  })
  await clock.advance(2000)

  expect(h.compacted).toHaveLength(1)
  expect(h.compacted[0]?.instructions).toContain(NOTE)

  // And the next turn is told to read it.
  expect(h.submitted).toHaveLength(2)
  expect(h.submitted[1]).toContain(NOTE)
  expect(h.submitted[1]).toMatch(/continue/i)
})

test('the focus typed after /handoff reaches the writing prompt', async ($, on) => {
  const h = harness()
  h.wire(on)
  const clock = mock.clock(on)

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.command.run(runHandoff('keep the parser work'))
  await clock.advance(600)

  expect(h.submitted[0]).toContain('keep the parser work')
})

test('a turn that writes nothing does not compact, and gives up quietly', async ($, on) => {
  const h = harness() // mtime stays -1: no note ever appears
  h.wire(on)
  const clock = mock.clock(on)

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.command.run(runHandoff())
  await clock.advance(600)

  for (let i = 0; i < 6; i++) {
    await $.turn.complete({
      answer: 'thinking...',
      reason: 'answer',
      durationMs: 1,
      isAborted: false,
      turnId: `t${i}`,
    })
    await clock.advance(2000)
  }

  expect(h.compacted).toHaveLength(0)
})

test('a vetoed compaction still saves the note and says so', async ($, on) => {
  let mtime = -1
  const h = harness({ mtime: () => mtime })
  h.setCompactResult({ skip: 'the PreCompact hook blocked it' })
  h.wire(on)
  const clock = mock.clock(on)

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.command.run(runHandoff())
  await clock.advance(600)

  mtime = 1000
  await $.turn.complete({
    answer: 'Saved.',
    reason: 'answer',
    durationMs: 1,
    isAborted: false,
    turnId: 't1',
  })
  await clock.advance(2000)

  // Compaction was attempted, was refused, and nothing was submitted to resume.
  expect(h.compacted).toHaveLength(1)
  expect(h.submitted).toHaveLength(1)
})

test('a compaction refused for good is not retried', async ($, on) => {
  let mtime = -1
  let attempts = 0
  const h = harness({
    mtime: () => mtime,
    // A permanent refusal: the mod must not spin on it.
    compact: () => {
      attempts += 1
      throw new Error('session.compact: compaction is switched off in this session (DISABLE_COMPACT)')
    },
  })
  h.wire(on)
  const clock = mock.clock(on)

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.command.run(runHandoff())
  await clock.advance(600)

  mtime = 1000
  await $.turn.complete({
    answer: 'Saved.',
    reason: 'answer',
    durationMs: 1,
    isAborted: false,
    turnId: 't1',
  })
  await clock.advance(5000)

  expect(attempts).toBe(1)
  expect(h.submitted).toHaveLength(1)
})

test('a stale note from an earlier handoff does not fire', async ($, on) => {
  // The file is already there, and stays the same all turn: nothing new written.
  const h = harness({ mtime: () => 500 })
  h.wire(on)
  const clock = mock.clock(on)

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.command.run(runHandoff())
  await clock.advance(600)

  await $.turn.complete({
    answer: 'Did something else.',
    reason: 'answer',
    durationMs: 1,
    isAborted: false,
    turnId: 't1',
  })
  await clock.advance(2000)

  expect(h.compacted).toHaveLength(0)
})

test('a subagent turn does not trigger the handoff', async ($, on) => {
  let mtime = -1
  const h = harness({ mtime: () => mtime })
  h.wire(on)
  const clock = mock.clock(on)

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.command.run(runHandoff())
  await clock.advance(600)

  mtime = 1000
  await $.turn.complete({
    answer: 'a subagent worked',
    reason: 'answer',
    durationMs: 1,
    isAborted: false,
    turnId: 't1',
    agentId: 'sub1',
  })
  await clock.advance(2000)

  expect(h.compacted).toHaveLength(0)
})
