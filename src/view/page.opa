module Page {

  function alert(message, cl) {
    <div class="alert alert-{cl}">
      <button type="button" class="close" data-dismiss="alert">×</button>
      {message}
    </div>
  }

  function page_template(title, content, notice) {
    html =
      <div class="navbar navbar-fixed-top">
        <div class=navbar-inner>
          <div class=container>
            {Topbar.html()}
          </div>
        </div>
      </div>
      <div id=#main>
        <span id=#notice class=container>{notice}</span>
        {content}
        {MsgUI.modal_window_html()}
        {Signin.modal_window_html()}
        {Signup.modal_window_html()}
      </div>
    Resource.page(title, html)
  }

  main_page_content =
    <div class=hero-unit>
        <h1>Birdy</h1>
        <h2>Micro-blogging platform.<br/>
          Built with <a href="http://opalang.org">Opa.</a>
        </h2>
        <p>{Signup.signup_btn_html}</p>
    </div>

  function main_page() {
    page_template("Birdy", main_page_content, <></>)
  }

  private function msgs_page(msgs, title, header, follow, unfollow, isFollowing) {
    recursive function do_follow(_) {
      _ = follow();
      #follow_btn = follow_btn();
    }
    and function do_unfollow(_) {
      _ = unfollow();
      #follow_btn = follow_btn();
    }
    and function follow_btn() {
      match (isFollowing()) {
      case {unapplicable}: <></>
      case {following}: <a class="btn" onclick={do_unfollow}>Unfollow</a>
      case {not_following}: <a class="btn btn-primary" onclick={do_follow}><i class="icon icon-white icon-plus"/> Follow</a>
      }
    }
    msgs_iter = DbSet.iterator(msgs)
    msgs_html = Iter.map(MsgUI.render, msgs_iter)
    content =
      <div class=container>
        <div class=user-info>
          {header}
          <div id=#follow_btn>{follow_btn()}</div>
        </div>
        {if (isFollowing() == {unapplicable} && Iter.is_empty(msgs_iter)) {
          <div class="well">
            <p>You don't have any messages yet. <a data-toggle=modal href="#{MsgUI.window_id}">Compose a new message</a>.</p>
          </div>
         } else <></>}
        <div id=#msgs>
         {msgs_html}
        </div>
      </div>
    page_template(title, content, <></>)
  }

  function topic_page(topic_name) {
    topic = Topic.create(topic_name)
    msgs = Msg.msgs_for_topic(topic)
    title = "#{topic}"
    header = <h3>{title}</h3>
    function follow() { User.follow_topic(topic) }
    function unfollow() { User.unfollow_topic(topic) }
    function isFollowing() { User.isFollowing_topic(topic) }
    msgs_page(msgs, title, header, follow, unfollow, isFollowing)
  }

  function user_page(username) {
    match (User.with_username(username)) {
    case {some: user}:
      msgs = Msg.msgs_for_user(user)
      title = "@{username}"
      header = <h3>{title}</h3>
      function follow() { User.follow_user(user) }
      function unfollow() { User.unfollow_user(user) }
      function isFollowing() { User.isFollowing_user(user) }
      msgs_page(msgs, title, header, follow, unfollow, isFollowing)
    case {none}:
      page_template("Unknown user: {username}", <></>,
        alert("User {username} does not exist", "error")
      )
    }
  }

}
