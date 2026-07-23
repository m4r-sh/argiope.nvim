const title = "Argiope";
const MYCLASS = "card";

const view = html`
  <main class="card">
    <h1>Embedded HTML</h1>
    <p>${title}</p>
  </main>
`;

const styles = css`
  .${MYCLASS} {
    background: #f00;
  }
`;

const notes = md`
# Embedded Markdown

- HTML templates
- CSS templates
`;
