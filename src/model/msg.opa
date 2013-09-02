abstract type Msg.t =
  { string content,
    User.t author,
    Date.date created_at,
    list(Topic.t) topic_refs,
    list(User.name) user_refs
  }

type Msg.segment =
  { string text } or
  { Uri.uri link } or
  { User.name user } or
  { Topic.t topic }

module Msg {

  private function list(Topic.t) get_all_topics(list(Msg.segment) msg) {
    function filter_topics(seg) {
      match (seg) {
      case ~{topic}: some(topic)
      default: none
      }
    }
    List.filter_map(filter_topics, msg)
  }

  private function list(User.name) get_all_users(list(Msg.segment) msg) {
    function filter_users(seg) {
      match (seg) {
      case ~{user}: some(user)
      default: none
      }
    }
    List.filter_map(filter_users, msg)
  }

  function Msg.t create(User.t author, string content) {
    msg_segs = analyze_content(content)
    { ~content, ~author,
      created_at: Date.now(),
      topic_refs: get_all_topics(msg_segs),
      user_refs: get_all_users(msg_segs)
    }
  }

  function get_author(Msg.t msg) { msg.author }
  function get_created_at(Msg.t msg) { msg.created_at }

  private function list(Msg.segment) analyze_content(string msg) {
    word = parser { case word=([a-zA-Z0-9_\-]+) -> Text.to_string(word) }
    element = parser {
    case "@" user=word: ~{user}
    case "#" topic=word: ~{topic}
       /* careful here, Uri.uri_parser too liberal, as it parses things like
          hey.ho as valid URLs; so we use "http://" prefix to recognize URLs */
    case &"http://" url=Uri.uri_parser: {link: url}
    }
    segment_parser = parser {
    case ~element: element
     /* below we eat a complete [word] or a single non-word character; the
        latter case alone may not be enough as we don't want:
        sthhttp://sth to pass for an URL. */
    case text=word: {~text}
    case c=(.): {text: Text.to_string(c)}
    }
    msg_parser = parser { case res=segment_parser*: res }
    Parser.parse(msg_parser, msg)
  }

  function list(Msg.segment) analyze(Msg.t msg) {
    analyze_content(msg.content)
  }

  function int length(Msg.t msg) {
    String.length(msg.content)
  }

  exposed function void store(Msg.t msg) {
    /birdy/msgs[{author:msg.author, created_at:msg.created_at}] <- msg;
  }

  function msgs_for_user(User.t user) {
    userdata = /birdy/users[{username: user.username}]
    /birdy/msgs[author.username in userdata.follows_users or
              topic_refs[_] in userdata.follows_topics or
              user_refs[_] == user.username or
              author.username == user.username;
              order -created_at;
              limit 50]
  }

  function msgs_for_topic(Topic.t topic) {
    /birdy/msgs[topic_refs[_] == topic; order -created_at; limit 50]
  }

}