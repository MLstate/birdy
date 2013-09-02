module MsgUI {

  window_id = "msgbox"

  private preview_content_id = "preview_content"
  private input_box_id = "input_box"
  private chars_left_id = "chars_left"
  private submit_btn_id = "submit_btn"

  private MAX_MSG_LENGTH = 140
  private MSG_WARN_LENGTH = 120

  private function render_segment(Msg.segment seg) {
    match (seg) {
    case ~{user}:
      <b><a class=ref-user href="/user/{user}">@{user}</a></b>
    case ~{topic}:
      <i><a class=ref-topic href="/topic/{topic}">#{topic}</a></i>
    case ~{link}:
      <a href={link}>{Uri.to_string(link)}</a>
    case ~{text}:
      <>{text}</>
    }
  }

  function xhtml render(Msg.t msg) {
    msg_author = Msg.get_author(msg)
    <div class=well>
      <p class="author-info">
        <strong><a href="/user/{msg_author}">@{msg_author}</a></strong>
        <span>{Date.to_string(Msg.get_created_at(msg))}</span>
      </p>
      <p>
        {List.map(render_segment, Msg.analyze(msg))}
      </p>
    </div>
  }

  private client function get_msg(user) {
    Dom.get_value(#{input_box_id})
    |> Msg.create(user, _)
  }

  private client function close() {
    Modal.hide(#{window_id})
  }

  private client function update_preview(user)(_) {
    msg = get_msg(user)
    #{preview_content_id} = render(msg)

     // show status
    msg_len = Msg.length(msg)
    #{chars_left_id} = MAX_MSG_LENGTH - msg_len
    remove = Dom.remove_class
    add = Dom.add_class
    remove(#{chars_left_id}, "char-error");
    remove(#{chars_left_id}, "char-warning");
    remove(#{submit_btn_id}, "disabled");
    Dom.set_enabled(#{submit_btn_id}, true);

    if (msg_len > MAX_MSG_LENGTH) {
      add(#{chars_left_id}, "char-error");
      add(#{submit_btn_id}, "disabled");
      Dom.set_enabled(#{submit_btn_id}, false);
    } else if (msg_len > MSG_WARN_LENGTH) {
      add(#{chars_left_id}, "char-warning");
    }
  }

  private function submit(user)(_) {
    get_msg(user) |> Msg.store;
    Dom.clear_value(#{input_box_id});
    close();
    Client.reload();
  }

  function modal_window_html() {
    match (User.get_logged_user()) {
    case {guest}: <></>
    case ~{user}:
      win_body =
        <textarea id={input_box_id} onready={update_preview(user)} onkeyup={update_preview(user)} placeholder="Compose a message"/>
        <div id=#preview_container>
          <p class=badge>Preview</p>
          <div id={preview_content_id} />
        </div>
      win_footer =
        <span class="char-wrap pull-left">
          <span id={chars_left_id} class="char"/>
          characters left
        </span>
        <button id={submit_btn_id} disabled=disabled class="pull-right btn btn-large btn-primary disabled" onclick={submit(user)}>
          Post
        </button>
      Modal.make(window_id, <>What's on your mind?</>, win_body, win_footer, Modal.default_options)
    }
  }

  function html() {
    match (User.get_logged_user()) {
    case {guest}: <></>
    case {user: _}:
      <a class="btn btn-primary pull-right" data-toggle=modal href="#{window_id}">
        <i class="icon-edit icon-white" />
        New message
      </a>
    }
  }

}