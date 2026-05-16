const fs = require('fs');
const path = require('path');
const { chromium } = require('C:/Users/yifei/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');

(async () => {
  const root = __dirname;
  const htmlPath = path.join(root, 'event-timeline-timeline-title-right-match.html');
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
    const lineCount = (el) => {
      if (!el) return 0;
      const range = document.createRange();
      range.selectNodeContents(el);
      const count = range.getClientRects().length;
      range.detach();
      return count;
    };

    return {
      timelineSelected: {
        firstNav: readRect(timelineTabs[0]),
        secondNav: readRect(timelineTabs[1]),
        firstWrap: readRect(timelineTabs[0]?.querySelector('.wrap')),
        secondWrap: readRect(timelineTabs[1]?.querySelector('.wrap')),
        secondText: Array.from(timelineTabs[1]?.childNodes || []).filter((node) => node.nodeType === Node.TEXT_NODE).map((node) => node.textContent.trim()).join(''),
        mark: readRect(timelineTabs[1]?.querySelector('.timeline-tab-mark')),
        markExists: Boolean(timelineTabs[1]?.querySelector('.timeline-tab-mark')),
      },
      timelineUnselected: {
        markExists: Boolean(recommendTabs[1]?.querySelector('.timeline-tab-mark')),
        secondText: Array.from(recommendTabs[1]?.childNodes || []).filter((node) => node.nodeType === Node.TEXT_NODE).map((node) => node.textContent.trim()).join(''),
        secondWrap: readRect(recommendTabs[1]?.querySelector('.wrap')),
        mark: readRect(recommendTabs[1]?.querySelector('.timeline-tab-mark')),
      },
      textRightEdges: {
        myCurrentCard: readRect(document.querySelector('[data-shot="my-current"] .topic.current')),
        myUnreadSecondCard: readRect(document.querySelector('[data-shot="my-unread"] .topic:nth-of-type(2)')),
        myUnreadSecondTitle: readRect(document.querySelector('[data-shot="my-unread"] .topic:nth-of-type(2) .title')),
        myCurrentCopy: readRect(document.querySelector('[data-shot="my-current"] .topic.current .topic-body > .copy')),
        myCurrentLatest: readRect(document.querySelector('[data-shot="my-current"] .topic.current .topic-latest-row')),
        timelineNodeSecondCard: readRect(document.querySelector('[data-shot="timeline-normal"] .node:nth-of-type(2)')),
        timelineNodeSecondTitle: readRect(document.querySelector('[data-shot="timeline-normal"] .node:nth-of-type(2) h3')),
        timelineNodeCard: readRect(document.querySelector('[data-shot="timeline-normal"] .node:nth-of-type(3)')),
        timelineNodeTitle: readRect(document.querySelector('[data-shot="timeline-normal"] .node:nth-of-type(3) h3')),
        timelineNodeSummary: readRect(document.querySelector('[data-shot="timeline-normal"] .node:nth-of-type(3) p')),
      },
      wrappingLines: {
        myCurrentTitle: lineCount(document.querySelector('[data-shot="my-current"] .topic.current .title')),
        myCurrentDirection: lineCount(document.querySelector('[data-shot="my-current"] .topic.current .topic-body > .copy')),
        myCurrentLatest: lineCount(document.querySelector('[data-shot="my-current"] .topic.current .topic-latest-row .latest')),
        recommendTitle: lineCount(document.querySelector('[data-shot="recommend-possible"] .rec .title')),
        recommendDirection: lineCount(document.querySelector('[data-shot="recommend-possible"] .rec .copy')),
      },
    };
  });

  console.log(JSON.stringify(metrics, null, 2));
  await browser.close();
})();
