(*
 * lTerm.mli
 * ---------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

(** Terminal definitions *)

type t
  (** Type of terminals. *)

(** {6 Creation} *)

val create :
  ?windows : bool ->
  ?model : string ->
  ?incoming_encoding : string ->
  ?outgoing_encoding : string ->
  Lwt_unix.file_descr -> Lwt_io.input_channel ->
  Lwt_unix.file_descr -> Lwt_io.output_channel -> t Lwt.t
  (** [create ?windows ?model ?incoming_encoding ?outgoing_encoding
      input_fd input_channel outout_fd output_channel] creates a new
      terminal using [input_fd] and [input_channel] for inputs and
      [output_fd] and [output_channel] for outputs.

      - [windows] is a flag telling whether windows hack should be
      used. It defaults to [Lwt_sys.windows].

      - [model] is the type of the terminal, such as "rxvt" or
      "xterm". It defaults to the contents of the "TERM" environment
      variable, or to "dumb" if this one is not found. It is used to
      determine capabilities of the terminal, such as the number of
      colors. This is not used if [windows] is [true].

      - [incoming_encoding] is the encoding used for incoming data. It
      defaults to [LTerm_windows.get_console_cp] if [windows] is [true]
      and [LTerm_unix.system_encoding] otherwise.

      - [outgoing_encoding] is the encoding used for outgoing data. It
      defaults to [LTerm_windows.get_console_output_cp] if [windows] is
      [true] and [LTerm_unix.system_encoding] otherwise. Note that
      transliteration is used so printing unicode character on the
      terminal will never fail. *)

(** {6 Informations} *)

val model : t -> string
  (** Returns the model of the terminal. *)

val colors : t -> int
  (** Number of colors of the terminal. *)

val windows : t -> bool
  (** Whether the terminal is in windows mode or not. *)

val is_a_tty : t -> bool
  (** [is_a_tty term] whether the intput and output of the given
      terminal are connected to a tty device. *)

val incoming_is_a_tty : t -> bool
  (** [incoming_is_a_tty term] whether the input of [term] is a tty
      device. *)

val outgoing_is_a_tty : t -> bool
  (** [incoming_is_a_tty term] whether the output of [term] is a tty
      device. *)

val escape_time : t -> float
  (** Time waited before returning the escape key. This is not used on
      windows. *)

val set_escape_time : t -> float -> unit
  (** Set the time waited before returning the escape key. *)

exception Not_a_tty
  (** Exception raised when trying to use a function that can only be
      used on terminals. *)

(** {6 Sizes} *)

val get_size : t -> LTerm_geom.size Lwt.t
  (** Returns the current size of the terminal.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

val set_size : t -> LTerm_geom.size -> unit Lwt.t
  (** Sets the current size of the terminal.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

(** {6 Modes} *)

type mode
  (** Type of terminal modes. *)

val enter_raw_mode : t -> mode Lwt.t
  (** [enter_raw_mode term] puts the terminal in ``raw mode''. In this
      mode keyboard events are returned as they happen. In normal mode
      only complete line are returned. It returns the current terminal
      mode that can be restored using {!leave_raw_mode}.

      It raises {!Not_a_tty} if the input of the given terminal is not
      tty. *)

val leave_raw_mode : t -> mode -> unit Lwt.t
  (** [leave_raw_mode term mode] leaves the raw mode by restoring the
      given mode.

      It raises {!Not_a_tty} if the input of the given terminal is not
      tty. *)

val enable_mouse : t -> unit Lwt.t
  (** Enable mouse events reporting.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

val disable_mouse : t -> unit Lwt.t
  (** Disable mouse events reporting.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

(** {6 Cursor} *)

val show_cursor : t -> unit Lwt.t
  (** Make the cursor visible.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

val hide_cursor : t -> unit Lwt.t
  (** Make the cursor invisible.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

val goto : t -> LTerm_geom.coord -> unit Lwt.t
  (** [goto term coord] moves the cursor to the given coordinates.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

val move : t -> int -> int -> unit Lwt.t
  (** [move term lines columns] moves the cursor by the given number
      of lines and columns. Both [lines] and [columns] may be
      negavite.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

(** {6 Erasing text} *)

val clear_screen : t -> unit Lwt.t
  (** [clear_screen term] clears the entire screen. *)

val clear_screen_next : t -> unit Lwt.t
  (** [clear_screen_next term] clears the screen from the cursor to
      the bottom of the screen. *)

val clear_screen_prev : t -> unit Lwt.t
  (** [clear_screen_prev term] clears the screen from the cursor to
      the top of the screen. *)

val clear_line : t -> unit Lwt.t
  (** [clear_line term] erases the current line. *)

val clear_line_next : t -> unit Lwt.t
  (** [clear_line_next term] erases the current line from the cursor
      to the end of the line. *)

val clear_line_prev : t -> unit Lwt.t
  (** [clear_line_prev term] erases the current line from the cursor
      to the beginning of the line. *)

(** {6 State} *)

val save_state : t -> unit Lwt.t
  (** Save the current state of the terminal so it can be restored
      latter.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

val load_state : t -> unit Lwt.t
  (** Load the previously saved state of the terminal.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

(** {6 Events} *)

val read_event : t -> LTerm_event.t Lwt.t
  (** Reads and returns one event. The terminal should be in raw mode
      before calling this function, otherwise event will not be
      reported as they happen. It does not fail if the terminal is not
      a tty. *)

(** {6 Printing} *)

(** The general name of a printing function is [<prefix>print<suffixes>].

    Where [<prefix>] is one of:
    - ['f'], which means that the function takes as argument a terminal
    - nothing, which means that the function prints on {!stdout}
    - ['e'], which means that the function prints on {!stderr}

    and [<suffixes>] is a combination of:
    - ['l'] which means that a new-line character is printed after the message
    - ['f'] which means that the function takes as argument a {b format} instead
    of a string
    - ['s'] which means that the function takes as argument a styled
    string instead of a string

    Notes:
    - if the terminal is not a tty, styles are stripped.
    - non-ascii characters are recoded on the fly using the terminal
    encoding
*)

val fprint : t -> string -> unit Lwt.t
val fprintl : t -> string -> unit Lwt.t
val fprintf : t -> ('a, unit, string, unit Lwt.t) format4 -> 'a
val fprints : t -> LTerm_text.t -> unit Lwt.t
val fprintlf : t -> ('a, unit, string, unit Lwt.t) format4 -> 'a
val fprintls : t -> LTerm_text.t -> unit Lwt.t
val print : string -> unit Lwt.t
val printl : string -> unit Lwt.t
val printf : ('a, unit, string, unit Lwt.t) format4 -> 'a
val prints : LTerm_text.t -> unit Lwt.t
val printlf : ('a, unit, string, unit Lwt.t) format4 -> 'a
val printls : LTerm_text.t -> unit Lwt.t
val eprint : string -> unit Lwt.t
val eprintl : string -> unit Lwt.t
val eprintf : ('a, unit, string, unit Lwt.t) format4 -> 'a
val eprints : LTerm_text.t -> unit Lwt.t
val eprintlf : ('a, unit, string, unit Lwt.t) format4 -> 'a
val eprintls : LTerm_text.t -> unit Lwt.t

(** {6 Rendering} *)

val render : t -> LTerm_draw.matrix -> unit Lwt.t
  (** Render an offscreen array to the given terminal.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

val render_update : t -> LTerm_draw.matrix -> LTerm_draw.matrix -> unit Lwt.t
  (** [render_update displayed to_display] does the same as [render
      to_display] but assumes that [displayed] contains the current
      displayed text. This reduces the amount of text sent to the
      terminal.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

(** {6 Misc} *)

val flush : t -> unit Lwt.t
  (** Flushes the underlying output channel used by the terminal. *)

(** {6 Well known instances} *)

val stdout : t Lwt.t Lazy.t
  (** Terminal using {!Lwt_unix.stdin} as input and {!Lwt_unix.stdout}
      as output. *)

val stderr : t Lwt.t Lazy.t
  (** Terminal using {!Lwt_unix.stdin} as input and {!Lwt_unix.stderr}
      as output. *)

(** {6 Low-level functions} *)

val get_size_from_fd : Lwt_unix.file_descr -> LTerm_geom.size Lwt.t
  (** [get_size_from_fd fd] returns the size of the terminal accessible via
      the given file descriptor. *)

val set_size_from_fd : Lwt_unix.file_descr -> LTerm_geom.size -> unit Lwt.t
  (** [set_size_from_fd fd size] tries to set the size of the terminal
      accessible via the given file descriptor. *)