# 快速阅读论文 — 配置指南

把一篇论文 PDF 生成一个**自包含的本地速读网页**:左侧 PDF.js 渲染原文,右侧按段落/章节/图表组织的中文极简讲解,开头一组核心词汇卡。整个文件夹可拷走/发人,Chrome 双击 `index.html` 即用,**无需服务器、无需联网**。

**完全免费、纯本地**,不调用任何付费 API。讲解由你的 agent(Claude / Codex / Gemini 等)亲自精读撰写。

---

## 1. 前置条件

| 依赖 | 用途 | 安装 |
|------|------|------|
| **Chrome** | 打开速读网页 + 渲染验证 | 官网下载 |
| **poppler** (`pdftotext`) | 从 PDF 抽全文 | `brew install poppler`(Linux: `apt install poppler-utils`) |
| **Node.js** | 跑 `verify_render.js` 渲染验证 | `brew install node` |
| **Python 3** | build.sh 内联 worker / 数页 | macOS/Linux 自带 |

## 2. 配置环境变量

**无需任何环境变量、API Key 或账号。** 纯本地工具。

## 3. 安装依赖

```bash
# macOS
brew install poppler node
# Linux (Debian/Ubuntu)
sudo apt install poppler-utils nodejs
```

## 4. 放置文件

把整个 `快速阅读论文/` 文件夹放到你的 agent 技能目录:

```bash
# Claude Code
cp -r 快速阅读论文 ~/.claude/commands/

# 其他 runtime(按需)
# cp -r 快速阅读论文 ~/.codex/skills/
# cp -r 快速阅读论文 ~/.gemini/skills/
```

> ⚠️ SKILL.md 内的命令示例写的是 `~/.claude/commands/快速阅读论文/scripts/build.sh`。如果你装到别的目录,把这个前缀换成你的实际路径即可(`scripts/build.sh` 用 `$SKILL_DIR` 自动定位自身,本身不依赖固定路径)。

## 5. 测试

随便找一篇论文 PDF 跑一遍:

```bash
SKILL=~/.claude/commands/快速阅读论文
bash $SKILL/scripts/build.sh "~/Downloads/some-paper.pdf" "~/Desktop/速读-test"
# 脚手架就绪后,正常流程是 agent 填讲解;先直接验证渲染:
node $SKILL/scripts/verify_render.js "~/Desktop/速读-test"
# 期望输出 RENDER_OK,并生成 _render_check.png
```

## 6. 配置为技能

放进 `~/.claude/commands/` 后,Claude Code 会自动发现(凭 `SKILL.md` 的 frontmatter)。新开 session 后直接说"帮我快速读这篇论文 <PDF路径>"即可触发。

---

## 跨平台注意

`scripts/verify_render.js` 第 11 行的 Chrome 路径默认是 **macOS**:

```js
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
```

- **Linux**:改成 `/usr/bin/google-chrome` 或 `google-chrome-stable`
- **Windows**:改成 `C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe`

验证步骤只在渲染检查时用到 Chrome;生成的 `index.html` 本身用任何现代浏览器双击即可打开。

## 使用示例

1. **读一篇刚下载的论文** —— "帮我快速读这篇论文 ~/Downloads/nature-xxxx.pdf",agent 跑 build.sh → 精读全文 → 填讲解 → 验证渲染 → 给你产物目录。
2. **做成可分享的速读包** —— 产物整个文件夹拷给同事,对方 Chrome 双击 `index.html` 即看,无需任何环境。
3. **批量速读** —— 对多篇 PDF 分别生成,每篇一个独立目录。

## 工作原理(关键设计)

- **PDF → base64 内联**:PDF 写进 `assets/paper-data.js`,绕开 `file://` 下的 CORS,纯离线可用。
- **blob worker**:`file://` 下 PDF.js 默认 worker 会被浏览器拦截,模板内联 worker 源码、运行时起同源 blob worker 解决。
- **CDP 真实渲染验证**:`verify_render.js` 用真实事件循环等 canvas 画出来再截图,而不是 `--virtual-time-budget`(后者驱动不了 worker,截图会骗人)。

## 常见问题

**Q: 网页一直停在"正在渲染 PDF…"?**
A: 用 Chrome 打开(其他浏览器对 `file://` worker 策略不同)。仍不行就跑 `verify_render.js` 看报错。

**Q: 讲解卡片里图表页码对不上?**
A: PDF.js 物理页码从 1 开始,**≠ 印刷页脚页码**。很多期刊正文物理页 = 印刷页 + 1(首页是图示摘要)。徽章用物理页码。

**Q: 网页白屏?**
A: 多半是讲解内容里用了英文直双引号 `"` 截断了 JS 字符串。内容里的引号一律用中文「」或弯引号 `""`。填完跑 `verify_render.js` 或 `node --check` 自检。

**Q: 怎么升级 PDF.js?**
A: 同步替换 `vendor/pdf.min.js` 和 `vendor/pdf.worker.min.js`(同一版本号),其余不动。当前版本 3.11.174。

## 第三方组件

`vendor/` 下的 `pdf.min.js` / `pdf.worker.min.js` 是 [PDF.js](https://github.com/mozilla/pdf.js)(Mozilla,Apache-2.0),为离线可用一并打包。
