export default (title) => html`
  <section class=${WRAP}>
    <div class=${BTN}>
      ${list.map(() => html`
        <span class=${LABEL}>
          ${title}
        </span>
      `)}
    </div>
  </section>
`
