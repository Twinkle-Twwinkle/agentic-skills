# 论文下载 — 安装与配置指南

批量下载学术论文 PDF，9 层下载策略 + Sci-Hub curl 兜底 + Cell.com Playwright 支持。

## 前置条件

- Python 3.9+
- pip3

## 安装依赖

```bash
# 必须
pip3 install requests aiohttp aiofiles

# 可选（增强反爬，强烈推荐）
pip3 install cloudscraper

# 可选（仅 Cell.com / Elsevier Cell Press 论文需要）
pip3 install playwright && playwright install chromium
```

## 放置文件

```bash
# 把技能文件夹整体放到 ~/.claude/commands/
cp -r skills/论文下载 ~/.claude/commands/
```

放置后目录结构：
```
~/.claude/commands/论文下载/
├── SKILL.md
└── scripts/
    ├── batch_download_papers.py   # 标准模式（<100篇）
    └── fast_download_papers.py    # 快速模式（>100篇）
```

## 快速测试

准备一个 DOI 列表文件（`test_dois.txt`）：

```
10.1038/s41586-023-06792-0
10.1126/science.abq0820
```

运行：

```bash
mkdir -p /tmp/test-papers/_build /tmp/test-papers/pdfs
python3 ~/.claude/commands/论文下载/scripts/batch_download_papers.py \
  --items-file test_dois.txt \
  --base-dir /tmp/test-papers/pdfs \
  --workers 4 \
  --report-json /tmp/test-papers/_build/_download_report.json \
  --report-md /tmp/test-papers/_build/_download_report.md
```

成功时 `pdfs/` 下会出现以 DOI 命名的子文件夹，每个包含 `paper.pdf`。

## 触发方式（Claude Code 内）

- "帮我下载这些论文" + DOI 列表
- "批量下载文献到 xxx 目录"
- 给一个含 DOI 的 .txt / .md / .csv 文件路径

## FAQ

**Q: cloudscraper 安装失败怎么办？**
A: 跳过即可，不影响主流程；仅对 Cloudflare 保护的站点有额外帮助。

**Q: Sci-Hub 镜像失效了怎么办？**
A: 在 SKILL.md「第 10 层」部分更新 `mirrors` 列表，当前可用镜像：`sci-hub.ren`、`sci-hub.ee`、`sci-hub.wf`。

**Q: OUP / NAR 论文全部失败？**
A: OUP 有 Cloudflare managed challenge，自动化工具无法绕过，直接让用户手动浏览器下载，见 `_需手动下载.md`。

**Q: PMC 下载返回 XML 不是 PDF？**
A: `efetch.fcgi` 接口只返回 XML，脚本已改用 `europepmc.org/articles/{pmcid}?pdf=render` 路径，正常。

**Q: Unpaywall 新论文总返回 null？**
A: Unpaywall 数据覆盖较慢，新论文建议优先走 OpenAlex 或 Crossref；`email` 参数占位符 `test@example.com` 大量调用时建议换成自己的邮箱。

## 第三方组件与 License

| 组件 | 用途 | License |
|------|------|---------|
| requests | HTTP 请求 | Apache-2.0 |
| aiohttp | 异步 HTTP（PMC 批量下载） | Apache-2.0 |
| cloudscraper | Cloudflare 反爬绕过 | MIT |
| playwright | Cell.com PDF 下载（可选） | Apache-2.0 |
