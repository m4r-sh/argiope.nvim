let MYCLASS = "TEST"

function render(title) {
  const view = html`
    <section>
      <header>
        <h1>${ title }</h1>
      </header>
      <main>
        <p>Body</p>
      </main>
    </section>
  `;
  return view;
}

export let styles = () => css`
  .${MYCLASS}{
  background: #f00;
  }
`
