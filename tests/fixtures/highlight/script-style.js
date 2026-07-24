const title = "Argiope";
const navHeight = "80px";

export function page() {
  return html`
    <html>
      <head>
        <title>${title}</title>
        <script>${raw.js`
          const LS = localStorage;
          const theme = LS.theme || "dark";
        `}</script>
        <style>
          :root {
            --navh: ${navHeight};
          }
        </style>
      </head>
    </html>
  `;
}
