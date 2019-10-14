(* (c) Romain Calascibetta 2019 *)

open Mirage

let remote =
  let doc = Key.Arg.info ~doc:"Remote Git repository." [ "r"; "remote" ] in
  Key.(create "remote" Arg.(opt string "git://127.0.0.1/pasteur" doc))

let port =
  let doc = Key.Arg.info ~doc:"port of HTTP service" [ "p"; "port" ] in
  Key.(create "port" Arg.(opt int 4343 doc))

let random_len =
  let doc = Key.Arg.info ~doc:"Length of generated URI" [ "length" ] in
  Key.(create "random_length" Arg.(opt int 3 doc))

let pasteur =
  foreign "Unikernel.Make"
    ~keys:[ Key.abstract remote; Key.abstract port; Key.abstract random_len ]
    (random @-> console @-> pclock @-> kv_ro @-> resolver @-> conduit @-> http @-> job)

let stack = generic_stackv4 default_network
let conduit = conduit_direct stack
let resolver = resolver_dns stack
let app = httpaf_server conduit
let console = console
let public = generic_kv_ro "public"

let packages =
  let irmin_pin = "git+https://github.com/pascutto/irmin.git#git_pp" in
  let git_pin = "git+https://github.com/dinosaure/ocaml-git.git#mirage.3.6.0" in
  let multipart_form = "git+https://github.com/dinosaure/multipart_form.git" in

  [ package ~pin:"git+https://github.com/dinosaure/httpaf.git#mirage" "httpaf"
  ; package ~pin:"git+https://github.com/dinosaure/httpaf.git#mirage" "httpaf-mirage"
  ; package ~pin:"git+https://github.com/dinosaure/httpaf.git#mirage" "httpaf-lwt"

  ; package ~pin:"git+https://github.com/mirage/uuuu.git" "uuuu"
  ; package ~pin:"git+https://github.com/mirage/coin.git" "coin"
  ; package ~pin:"git+https://github.com/mirage/yuscii.git" "yuscii"
  ; package ~pin:"git+https://github.com/mirage/rosetta.git" "rosetta"
  ; package ~pin:multipart_form "multipart_form"

  ; package ~min:"0.9.0" ~max:"1.0.0" "decompress"
  ; package ~pin:git_pin "git"
  ; package ~pin:git_pin "git-http"
  ; package ~pin:git_pin "git-mirage"

  ; package ~sublibs:["c"] "checkseum" ~min:"0.0.9"
  ; package ~sublibs:["c"] "digestif" ~min:"0.7.4"

  ; package ~pin:irmin_pin "irmin"
  ; package ~pin:irmin_pin "irmin-mem"
  ; package ~pin:irmin_pin "irmin-git"
  ; package ~pin:irmin_pin "irmin-mirage"
  ; package ~pin:irmin_pin "irmin-mirage-git"
  ; package ~pin:multipart_form "multipart_form"

  ; package "uuidm"
  ; package "tyxml" ]

let () =
  register "pasteur"
    ~packages
    [ pasteur $ default_random $ default_console $ default_posix_clock $ public $ resolver $ conduit $ app ]
