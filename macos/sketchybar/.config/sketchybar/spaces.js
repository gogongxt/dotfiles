#!/opt/homebrew/bin/node

const { execSync } = require("node:child_process")

const SID = Number(process.env.SID)
const SELECTED = process.env.SELECTED === "true"

console.log({
    SID,
    SELECTED
})

const windows = JSON.parse(execSync("/opt/homebrew/bin/yabai -m query --windows").toString())

const spaceWindows = windows.filter(a => a.space === SID && a["is-hidden"] === false && a["is-minimized"] === false)

const windowIds = spaceWindows.map(a => `win.${SID}.${a.id}`)


// we have to remove the last created group for this space, because there seems
// to be no way to update or to re-add a group, so whenever we focus on a space
// we remove its previous group, sot he create at the end of the script will
// work
if (SELECTED) {
    try {
        execSync(`/opt/homebrew/bin/sketchybar --remove win.${SID}`)
    } catch (e) {
        // console.warn(e)
    }
}

/**
 * remove out-dated windows
 */
{
    let shownOnes = undefined

    try {
        shownOnes = JSON.parse(execSync(`
            /opt/homebrew/bin/sketchybar --query win.${SID}
        `).toString())
        console.log(shownOnes.bracket)
    } catch (e) {
        // console.warn(e)
    }

    if (shownOnes) {
        const toBeRm = []

        for (const shownOne of shownOnes.bracket) {
            if (shownOne === `space.${SID}` || windowIds.includes(shownOne)) {
                continue
            }

            toBeRm.push(shownOne)
        }

        console.log({ toBeRm })

        if (toBeRm.length > 0) {
            execSync(`
                /opt/homebrew/bin/sketchybar ${toBeRm.map(a => `--remove ${a}`).join(" ")}`)
        }
    }
}

/*
 * add windows
 */
for (const [index, win] of spaceWindows.entries()) {
    const itemId = `win.${SID}.${win.id}`
    const itemPos = "q" // 这里改为固定的"q"

    const cmd = `
        /opt/homebrew/bin/sketchybar --add item ${itemId} ${itemPos} \
            --set space.${SID} \
                icon.color=${SELECTED ? "0xa0ffffff" : "0x80ffffff"} \
            --set ${itemId} \
                background.padding_right=${index === 0 ? "5" : "0"}\
                background.drawing=true \
                background.height=10 \
                background.image.scale=0.75 \
                background.image="app.${win.app}" \
            --move ${itemId} before space.${SID} // 这里也改为固定的"before"
    `
    execSync(cmd)
}

/**
 * add group containing space indicator and window items
 */
execSync(`
    /opt/homebrew/bin/sketchybar --add bracket win.${SID} space.${SID} '/win\.${SID}.*/' \
        --set win.${SID} \
                background.height=28 \
                background.border_width=${SELECTED ? "0" : "1"} \
                background.border_color=${SELECTED ? "0x80ffffff" : "0x80ffffff"} \
                background.corner_radius=${SELECTED ? "5" : "5"} \
                background.color=${SELECTED ? "0x80ffffff" : "0x00ffffff"}
    `)
