import gleam/erlang/port
import gleam/erlang/port/receive.{Data, ExitStatus}
import gleam/erlang/process.{receive, port_open, port_subject}

pub fn port_open_test() {
  let assert Ok(port) = port.open(
    port.spawn_executable("/bin/bash"),
    [port.Args(["-c", "echo hi | wc -c"]), port.UseStdio, port.ExitStatus, port.Binary]
  )

  let subject = port_subject(port)

  assert Ok(Data(<<"3\n">>)) == receive(subject, 100)
  assert Ok(ExitStatus(0)) == receive(subject, 100)
  assert Error(Nil) == receive(subject, 100)
}

pub fn fail_port_open_test() {
  let assert Error(port.Enoent) = port.open(
    port.spawn_executable("/bin/doesntexist"),
    []
  )
}

pub fn port_subject_test() {
  let assert Ok(subject) = port_open(
    port.spawn_executable("/bin/bash"),
    [port.Args(["-c", "echo hello | wc -c"]), port.UseStdio, port.ExitStatus, port.Binary]
  )

  assert Ok(Data(<<"6\n">>)) == receive(subject, 100)
  assert Ok(ExitStatus(0)) == receive(subject, 100)
  assert Error(Nil) == receive(subject, 100)
}

pub fn close_port_test() {
  let assert Ok(port) = port.open(
    port.spawn_executable("/bin/bash"),
    [port.Args(["-c", "echo hi; sleep 0.25; echo yo 2> /dev/null"]), port.UseStdio, port.ExitStatus, port.Binary]
  )

  let subject = port_subject(port)

  assert Ok(Data(<<"hi\n">>)) == receive(subject, 100)

  port.close(port)

  assert Error(Nil) == receive(subject, 300)
}

pub fn delay_port_test() {
  let assert Ok(port) = port.open(
    port.spawn_executable("/bin/bash"),
    [port.Args(["-c", "echo hi; sleep 0.25; echo yo 2> /dev/null"]), port.UseStdio, port.ExitStatus, port.Binary]
  )

  let subject = port_subject(port)
  assert Ok(Data(<<"hi\n">>)) == receive(subject, 50)
  assert Error(Nil) == receive(subject, 100)
  assert Ok(Data(<<"yo\n">>)) == receive(subject, 300)
  assert Ok(ExitStatus(0)) == receive(subject, 100)
  assert Error(Nil) == receive(subject, 100)
}
