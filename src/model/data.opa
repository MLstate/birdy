database birdy {
  User.info /users[{username}]
  Msg.t /msgs[{author, created_at}]
}

module Data {

  main_host = "localhost"
  main_port = ":8080"

}
