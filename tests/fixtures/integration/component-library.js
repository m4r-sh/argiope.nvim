import { html, css, md, classify } from 'component-library'

const { WRAP, BTN, LABEL } = classify('MyButton')

export default (title) => html`
  <section class=${WRAP}>
    <div class=${BTN}>
      <span class=${LABEL}>
  ${title}
      </span>
    </div>
  </section>
`

export let style = () => css`
  .${BTN}{
    background: #fff;
    border: 2px solid red;
    color: #ff0000;
  }
`

export let docs = (title) => md`
  # ${title}

  This is the description of the UI component

- Feature 1
- Feature 2
- Feature 3
`
