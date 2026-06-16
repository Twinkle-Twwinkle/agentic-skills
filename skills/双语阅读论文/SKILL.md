---
name: 双语阅读论文
description: 把一篇论文 PDF 生成一个自包含的本地双语速读网页——左侧 PDF 原文、右侧中文极简讲解（含英文对照段落），顶部 toggle 可一键显示/隐藏全部英文。英文内容用论文原文表达风格改写，非逐字翻译。技术上：PDF 转 base64 内联 + blob worker（绕 file:// 限制），单文件夹双击即用、离线。触发：'双语阅读论文'/'中英对照读论文'/'帮我生成双语速读页'/'把这篇论文做成双语网页'/给一个论文 PDF 路径说想双语阅读。
---

# 双语阅读论文 → 本地双语速读网页

## 目标

给定一篇论文 PDF，产出一个**自包含的本地 HTML 网页**：

- **左侧** PDF.js 渲染论文原文（逐页、可滚动缩放）。
- **右侧** 中文极简讲解，按论文段落/章节/图表组织，开头一组核心词汇卡。每个 point 的中文内容后紧跟一段英文对照，用论文原文的表达风格改写（非翻译）。
- 顶部导航栏有 **「EN 隐藏/显示」toggle**，一键收起/展开所有英文段落。
- 右侧每张卡片有 `📄P#` 徽章，点击左侧 PDF 跳到对应页并高亮；导航条吸顶常驻；`A−/A+` 调讲解字号。
- 整个文件夹可拷走/发人，Chrome 双击 `index.html` 即用，**无需服务器、无需联网**。

讲解风格：**短、直接、便于扫读**。不做长篇翻译，每个大段配一两句话，每张图逐 panel(A/B/C…) 一句话。英文段落用斜体灰色左边线与中文区分。Claude **亲自精读全文**撰写（质量第一，不要批量生成）。

## 工作流

### 1. 脚手架（机械步骤，一条命令）

```bash
bash ~/.claude/commands/双语阅读论文/scripts/build.sh "<论文PDF路径>" "<输出目录>"
# 例：build.sh "~/Downloads/paper.pdf" "~/Desktop/论文双语-XXX"
```

它会：拷 PDF、`pdftotext` 抽全文、PDF→base64 内联（`assets/paper-data.js`）、准备 `vendor/`（pdf.min.js + 内联 worker）、把 `template.html` 拷成 `index.html`，并打印 PDF 物理页数。

### 2. 精读（Claude 亲自做）

- `Read <输出目录>/assets/fulltext.txt` 通读全文，建立章节/图表结构。
- 用 `Read` 工具**直接读 PDF**（`pages` 参数，一次 ≤20 页）逐页看图，确认每个图/章节落在**第几物理页**。
  - ⚠️ **物理页码 ≠ 印刷页脚页码**。PDF.js 从 1 开始数物理页；很多期刊正文物理页 = 印刷页+1（首页是图示摘要）。徽章 `page` 用**物理页码**。
- 心里列出：核心词汇 → 摘要/引言 → 结果各部分(每图一卡) → 讨论 → 方法。

### 3. 填占位符（用 Edit 改 `index.html`）

- 顶部三处：`__中文标题__` / `__英文原标题__` / `__meta__`（作者·期刊·年份·DOI）。
- `const SECTIONS = [...]`：替换为真实讲解。四种卡片 kind：

| kind | 用途 | 形态 |
|---|---|---|
| `terms` | 开篇核心词汇卡（绿底） | `{kind:"terms",page,t:"分组名",points:[[术语名（中英）, 中文解释, 英文改写?],…]}` |
| `lead` | 一句话核心 | `` {kind:"lead",page,html:`中文HTML`,en_html:`英文HTML`（可选）} `` |
| `card` | 普通段落讲解 | `{kind:"card",page,t:"标题",points:[[小标签, 中文说明, 英文改写?],…]}` |
| `fig` | 图表讲解（黄底📊） | `{kind:"fig",page,t:"图N",points:[[panel, 中文讲解, 英文改写?],…]}` |

**英文改写规则**：用论文自身的术语和句式重写该要点，不是直接翻译中文——读起来像论文摘要/结果章节的语气。`p[2]` 省略时不显示英文段落（允许按需选填）。

  开头建议放一个 `🔑 核心词汇（读前必看）` section，分「方法与工具/研究对象/核心概念」几组 `terms` 卡。

### 4. 验证（必做，别靠肉眼假设）

```bash
node ~/.claude/commands/双语阅读论文/scripts/verify_render.js "<输出目录>"
```

它用真实 CDP 事件循环渲染，等 canvas 真画出来，输出 `RENDER_OK`/`RENDER_FAIL` 并存 `<输出目录>/_render_check.png`。然后 `Read` 那张截图，肉眼确认左 PDF、右讲解、EN toggle、词汇卡都对。

> 顺手的语法自检：`node --check`（先把 `<script>…</script>` 抽出来），能在渲染前抓出引号问题。

## 关键踩坑（务必遵守，都是踩过的坑）

1. **引号陷阱**：`SECTIONS` 里内容字符串大多用英文双引号 `"…"` 包裹，所以**内容内部的引号一律用中文「」或弯引号 `""`**，绝不能用英文直双引号——否则提前截断 JS 字符串，整个网页白屏。英文改写段落尤其容易踩这个坑。填完务必 `node --check` 或 verify。

2. **file:// 下 Worker 被拦**：PDF.js 默认 `new Worker('./vendor/pdf.worker.min.js')` 在 `file://` 会被浏览器安全策略拒绝且不一定 fallback → 永远 loading。解法（模板已内置）：内联 worker 源码为 JS 字符串，运行时 `new Blob([code]) → URL.createObjectURL → workerSrc`，起**同源 blob worker**。

3. **headless 截图会骗人**：`chrome --headless --screenshot --virtual-time-budget` 驱动不了 Worker 线程，截图永远停在 loading。**必须用 `verify_render.js`（CDP 真实事件循环 + 轮询 canvas）**来验证，不要用 virtual-time 截图下结论。

4. **base64 内联**：PDF 不靠 `fetch` 本地文件（file:// CORS 拦），而是 base64 写进 `paper-data.js`，运行时 `atob`→`Uint8Array`→`getDocument({data})`。所以单文件夹纯离线可用。

5. **布局**：标题/导航在**右栏开头**且导航条 `position:sticky` 吸顶（不占垂直高度，左右栏都用满 `100vh`）。`A−/A+` 只 `zoom` 讲解正文（`#guide-body`），不缩放标题。

## 文件清单

```
双语阅读论文/
├── SKILL.md                    # 本文档
├── template.html               # 网页骨架（CSS/JS/布局/EN toggle + 占位符）
├── vendor/
│   ├── pdf.min.js              # PDF.js 库（3.11.174，缓存离线）
│   └── pdf.worker.min.js       # worker 源（build 时转 inline）
└── scripts/
    ├── build.sh                # 脚手架：PDF→assets/vendor/index.html
    └── verify_render.js        # CDP 真实渲染验证 + 截图
```

产物目录（每篇论文一个）：`index.html` + `assets/{paper.pdf,paper-data.js,fulltext.txt}` + `vendor/{pdf.min.js,pdf.worker.inline.js}`，约 PDF 体积的 ~1.3 倍。

## 升级 PDF.js

换版本时同步替换 `vendor/pdf.min.js` 与 `vendor/pdf.worker.min.js`（同一版本号），其余不动。

## 卸载

`rm -rf ~/.claude/commands/双语阅读论文/`
