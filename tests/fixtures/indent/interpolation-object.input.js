export default ({ active = "" } = {}) => html`
  <div class=${NAV} id="nav-mgmt">
    <div class=${T}>
      <div class=${T.L}>
      </div>
      <div class=${T.C}>
        ${Button({
        label: "Settings",
        className: BTN.SETTINGS,
        })}
      </div>
      <div class=${T.R}>
        ${Button({ label: "Settings" })}
      </div>
    </div>
    <div class=${B}>
    </div>
  </div>
  <div class=${NAV.PADDING} />
`
