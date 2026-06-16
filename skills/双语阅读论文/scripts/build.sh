#!/usr/bin/env bash
# 论文速读网页脚手架（机械步骤，零 token）：PDF → assets + vendor + index.html
# 用法: build.sh <论文PDF路径> <输出目录>
# 之后由 Claude 精读论文、填 index.html 的占位符，再跑 verify_render.js 验证
set -euo pipefail
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PDF="${1:?用法: build.sh <PDF路径> <输出目录>}"
OUT="${2:?用法: build.sh <PDF路径> <输出目录>}"

command -v pdftotext >/dev/null || { echo "❌ 缺 pdftotext，先 brew install poppler"; exit 1; }
[ -f "$PDF" ] || { echo "❌ 找不到 PDF: $PDF"; exit 1; }

mkdir -p "$OUT/assets" "$OUT/vendor"
cp "$PDF" "$OUT/assets/paper.pdf"
pdftotext "$OUT/assets/paper.pdf" "$OUT/assets/fulltext.txt"

# PDF → base64 内联（关键：避免 file:// 下 PDF.js fetch 本地文件的 CORS 限制）
{ printf 'window.PDF_B64="'; base64 -i "$OUT/assets/paper.pdf" | tr -d '\n'; printf '";'; } > "$OUT/assets/paper-data.js"

# vendor：PDF.js 库 + 内联 worker（file:// 下用 blob URL 起同源 worker，见 SKILL.md 踩坑②）
cp "$SKILL_DIR/vendor/pdf.min.js" "$OUT/vendor/pdf.min.js"
SKILL_DIR="$SKILL_DIR" OUT="$OUT" python3 - << 'PYEOF'
import os, json
sd, o = os.environ['SKILL_DIR'], os.environ['OUT']
c = open(sd+'/vendor/pdf.worker.min.js', encoding='utf-8').read()
open(o+'/vendor/pdf.worker.inline.js','w',encoding='utf-8').write('window.PDF_WORKER_CODE='+json.dumps(c)+';')
PYEOF

# 模板 → index.html（占位符待 Claude 填）
cp "$SKILL_DIR/template.html" "$OUT/index.html"

PAGES=$(OUT="$OUT" python3 -c "import os;print(open(os.environ['OUT']+'/assets/fulltext.txt').read().count(chr(12))+1)")
echo "✅ 脚手架就绪: $OUT"
echo "   PDF 物理页数 ≈ ${PAGES}（PDF.js 页码从 1 开始 = 物理页；注意 ≠ 印刷页脚页码）"
echo "   下一步:"
echo "     1) 读 $OUT/assets/fulltext.txt 通读全文 + Read PDF 逐图确认页码/看图"
echo "     2) 用 Edit 填 $OUT/index.html 里的 __标题__/__英文__/__meta__ 和 const SECTIONS"
echo "     3) node $SKILL_DIR/scripts/verify_render.js \"$OUT\" 验证渲染"
