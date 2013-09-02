abstract type User.name = string

abstract type User.status = {active} or {string activation_code}

abstract type User.info =
  { Email.email email,
    string username,
    string passwd,
    User.status status,
    list(User.name) follows_users,
    list(Topic.t) follows_topics
  }

type User.t = { Email.email email, User.name username }

type User.logged = {guest} or {User.t user}

module User {

  @xmlizer(User.t) function user_to_xml(user) {
    <>{user.username}</>
  }

  @stringifier(User.t) function user_to_string(user) {
    user.username
  }

  private UserContext.t(User.logged) logged_user = UserContext.make({guest})

  function string get_name(User.t user) {
    user.username
  }

  private function send_registration_email(args) {
    from = Email.of_string("no-reply@{Data.main_host}")
    subject = "Birdy says welcome"
    email =
      <p>Hello {args.username}!</p>
      <p>Thank you for registering with Birdy.</p>
      <p>Activate your account by clicking on
         <a href="http://{Data.main_host}{Data.main_port}/activation/{args.activation_code}">this link</a>.
      </p>
      <p>Happy messaging!</p>
      <p>--------------</p>
      <p>The Birdy Team</p>
    content = {html: email}
    continuation = function(_) { void }
    SmtpClient.try_send_async(from, args.email, subject, content, Email.default_options, continuation)
  }

  private function User.t mk_view(User.info info) {
    {username: info.username, email: info.email}
  }

  function option(User.t) with_username(string name) {
    ?/birdy/users[{username: name}] |> Option.map(mk_view, _)
  }

  exposed function outcome register(user) {
    activation_code = Random.string(15)
    status =
      #<Ifstatic:NO_ACTIVATION_MAIL>
      {active}
      #<Else>
      {~activation_code}
      #<End>
    user =
      { email: user.email,
        username: user.username,
        passwd: user.passwd,
        follows_users: [],
        follows_topics: [],
        ~status
      }
    x = ?/birdy/users[{username: user.username}]
    match (x) {
      case {none}:
        /birdy/users[{username: user.username}] <- user
        #<Ifstatic:NO_ACTIVATION_MAIL>
        void
        #<Else>
        send_registration_email({~activation_code, username:user.username, email: user.email})
        #<End>
        {success}
      case {some: _}:
        {failure: "User with the given name already exists."}
    }
  }

  exposed function outcome activate_account(activation_code) {
    user = /birdy/users[status == ~{activation_code}]
        |> DbSet.iterator
        |> Iter.to_list
        |> List.head_opt
    match (user) {
    case {none}: {failure}
    case {some: user}:
      /birdy/users[{username: user.username}] <- {user with status: {active}}
      {success}
    }
  }

  exposed function outcome(User.t, string) login(username, passwd) {
    x = ?/birdy/users[~{username}]
    match (x) {
    case {none}: {failure: "This user does not exist."}
    case {some: user}:
      match (user.status) {
      case {activation_code: _}:
        {failure: "You need to activate your account by clicking the link we sent you by email."}
      case {active}:
        if (user.passwd == passwd) {
          user_view = mk_view(user)
          UserContext.set(logged_user, {user: user_view})
          {success: user_view}
        } else
          {failure: "Incorrect password. Try again."}
      }
    }
  }

  function User.logged get_logged_user() {
    UserContext.get(logged_user)
  }

  private function do_if_logged_in(action) {
    match (get_logged_user()) {
    case {guest}: void
    case {user: me}: action(me)
    }
  }

  function follow_user(user) {
    function mk_follow(me) {
      /birdy/users[{username: me.username}]/follows_users <+ user.username
    }
    do_if_logged_in(mk_follow)
  }

  function unfollow_user(user) {
    function mk_unfollow(me) {
      /birdy/users[username == me.username]/follows_users <-- [user.username]
    }
    do_if_logged_in(mk_unfollow)
  }

  function isFollowing_user(user) {
    match (get_logged_user()) {
    case {guest}: {unapplicable}
    case {user: me}:
      if (user.username == me.username) {
        {unapplicable}
      } else {
        if (/birdy/users[username == me.username and follows_users[_] == user.username]
            |> DbSet.iterator |> Iter.is_empty) {
          {not_following}
        } else {
          {following}
        }
      }
    }
  }

  function follow_topic(topic) {
    function mk_follow(me) {
      /birdy/users[{username: me.username}]/follows_topics <+ topic
    }
    do_if_logged_in(mk_follow)
  }

  function unfollow_topic(topic) {
    function mk_unfollow(me) {
      /birdy/users[username == me.username]/follows_topics <-- [topic]
    }
    do_if_logged_in(mk_unfollow)
  }

  function isFollowing_topic(topic) {
    match (get_logged_user()) {
    case {guest}: {unapplicable}
    case {user: me}:
      if (/birdy/users[username == me.username and follows_topics[_] == topic]
          |> DbSet.iterator |> Iter.is_empty) {
        {not_following}
      } else {
        {following}
      }
    }
  }

  function logout() {
    UserContext.set(logged_user, {guest})
  }

}
