module Controller {

  // URL dispatcher of your application; add URL handling as needed
  function dispatcher(Uri.relative url) {
    match (url) {
    case {path: ["activation", activation_code] ...}:
      Signup.activate_user(activation_code)
    case {path:["user", user | _] ...}:
      Page.user_page(user)
    case {path:["topic", topic | _] ...}:
      Page.topic_page(topic)
    default:
      match (User.get_logged_user()) {
      case {~user}: Page.user_page(User.get_name(user))
      default: Page.main_page()
      }
    }
  }

}

resources = @static_resource_directory("resources")

Server.start(Server.http, [
  { register:
    [ { doctype: { html5 } },
      { css: ["/resources/css/style.css"] }
    ]
  },
  { ~resources },
  { dispatch: Controller.dispatcher }
])