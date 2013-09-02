module Signin {

  window_id = "signin"

  private fld_username =
    Field.text_field({Field.new with
      label: "Username",
      required: {with_msg: <>Please enter your username.</>}
    })

  private fld_passwd =
    Field.passwd_field({Field.new with
      label: "Password",
      required: {with_msg: <>Please enter your password.</>}
    })

  private function register(_) {
    Modal.hide(#{window_id});
    Modal.show(#{Signup.window_id});
  }

  private function signin(redirect, _) {
    username = Field.get_value(fld_username) ? error("Cannot get login")
    passwd = Field.get_value(fld_passwd) ? error("Cannot get passwd")
    match (User.login(username, passwd)) {
    case {failure: msg}:
      #signin_result =
        <div class="alert alert-error">
          {msg}
        </div>
       // FIXME This certainly should not be that complex... what am I missing?
      Dom.transition(#signin_result, Dom.Effect.sequence([
        Dom.Effect.with_duration({immediate}, Dom.Effect.hide()),
        Dom.Effect.with_duration({slow}, Dom.Effect.fade_in())
      ])) |> ignore
    case {success: _}:
      match (redirect) {
      case {none}: Client.reload()
      case {some:url}: Client.goto(url)
      }
    }
  }

  function form() {
    form = Form.make(signin(some("/"), _), {})
    fld = Field.render(form, _)
    form_body =
      <div class="signin_form">
        <legend>Sign in and start messaging</legend>
        {fld(fld_username)}
        {fld(fld_passwd)}
        <a href="#" class="btn btn-primary btn-large"
           onclick={Form.submit_action(form)}>Sign in</>
      </div>
    Form.render(form, form_body)
  }

  function modal_window_html() {
    form = Form.make(signin(none, _), {})
    fld = Field.render(form, _)
    form_body =
      <>
        {fld(fld_username)}
        {fld(fld_passwd)}
        <div id=#signin_result />
        <div class="control-group">
          <div class="controls">New to Birdy? <a onclick={register}>Sign up</>.</div>
        </div>
      </>
    win_body = Form.render(form, form_body)
    win_footer =
      <a href="#" class="btn btn-primary btn-large" onclick={Form.submit_action(form)}>Sign in</>
    Modal.make(window_id, <>Sign in</>, win_body, win_footer, Modal.default_options)
  }

}
