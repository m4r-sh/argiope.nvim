export default ({ name, min, max, value, step } = params) => html`
<div class=${SLIDER.WRAP}>
<div class=${SLIDER}>
<div class=${INPUTS}>
<input class=${RANGE} type="range" name=${name} min=${min} max=${max} step=${step} value=${value} tabindex="-1" />
</div>
<div class=${VIEW}>
<div class=${VIEW.RAIL}>
<div class=${VIEW.DOT} />
</div>
<input class=${VIEW.TEXT} pattern="[0-9]*" inputmode="numeric" value=${value} type="text" />
</div>
</div>
</div>
</div>
`
