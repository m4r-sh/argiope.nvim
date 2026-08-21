export default ({
info = {},
toc = []
} = {}) => html`
<div class=${WRAP}>
<div class=${INFO}>
</div>
<div class=${TOC}>
${toc.map(item => html`
<a class=${ITEM} href=${item.href}>
<span class=${ITEM.TITLE}>
${item.name}
</span>
</a>
`)}
</div>
</div>
`
