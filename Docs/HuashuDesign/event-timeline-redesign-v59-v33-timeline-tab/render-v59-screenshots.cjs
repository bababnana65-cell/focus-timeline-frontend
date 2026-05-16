const fs = require('fs');
const path = require('path');
const { chromium } = require('C:/Users/yifei/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');

(async () => {
  const root = __dirname;
  const htmlPath = path.join(root, 'event-timeline-v33-timeline-tab.html');
  const boardPath = path.join(root, 'screenshots', 'design-board.png');
  const screensDir = path.join(root, 'screens');

  fs.mkdirSync(path.dirname(boardPath), { recursive: true });
  fs.mkdirSync(screensDir, { recursive: true });

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1600, height: 1800 }, deviceScaleFactor: 1 });
  await page.goto(`file:///${htmlPath.replace(/\\/g, '/')}`);
  await page.waitForTimeout(250);
  await page.screenshot({ path: boardPath, fullPage: true });

  const shots = await page.$$('[data-shot]');
  for (const shot of shots) {
    const name = await shot.getAttribute('data-shot');
    if (!name) continue;
    await shot.screenshot({ path: path.join(screensDir, `${name}.png`) });
  }

  const metrics = await page.evaluate(() => {
    const readRect = (el) => {
      if (!el) return null;
      const rect = el.getBoundingClientRect();
      return {
        top: Math.round(rect.top),
        bottom: Math.round(rect.bottom),
        left: Math.round(rect.left),
        right: Math.round(rect.right),
        width: Math.round(rect.width),
        height: Math.round(rect.height),
      };
    };

    const timeline = document.querySelector('[data-shot="timeline-normal"] .bottom');
    const recommend = document.querySelector('[data-shot="recommend-possible"] .bottom');
    const timelineTabs = timeline ? Array.from(timeline.querySelectorAll('.nav')) : [];
    const recommendTabs = recommend ? Array.from(recommend.querySelectorAll('.nav')) : [];
    const readText = (nav) => Array.from(nav?.childNodes || [])
      .filter((node) => node.nodeType === Node.TEXT_NODE)
      .map((node) => node.textContent.trim())
      .join('');

    return {
      timelineSelected: {
        secondNav: readRect(timelineTabs[1]),
        secondWrap: readRect(timelineTabs[1]?.querySelector('.wrap')),
        secondIcon: readRect(timelineTabs[1]?.querySelector('.icon')),
        secondText: readText(timelineTabs[1]),
        usesClock: timelineTabs[1]?.querySelector('use')?.getAttribute('href') === '#clock',
        hasCustomTimelineMark: Boolean(timelineTabs[1]?.querySelector('.timeline-tab-mark')),
      },
      timelineUnselected: {
        secondNav: readRect(recommendTabs[1]),
        secondWrap: readRect(recommendTabs[1]?.querySelector('.wrap')),
        secondIcon: readRect(recommendTabs[1]?.querySelector('.icon')),
        secondText: readText(recommendTabs[1]),
        usesClock: recommendTabs[1]?.querySelector('use')?.getAttribute('href') === '#clock',
        hasCustomTimelineMark: Boolean(recommendTabs[1]?.querySelector('.timeline-tab-mark')),
      },
    };
  });

  fs.writeFileSync(path.join(root, 'screenshot-metrics.json'), `${JSON.stringify(metrics, null, 2)}\n`);

  await browser.close();
})();
