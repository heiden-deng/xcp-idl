(*
 * Copyright (C) Citrix Systems Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; version 2.1 only. with the special
 * exception on linking described in file LICENSE.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *)

open Storage_interface
open Xcp_client

let rec retry_econnrefused f =
  try
    f ()
  with
  | Unix.Unix_error(Unix.ECONNREFUSED, "connect", _) ->
      (* debug "Caught ECONNREFUSED; retrying in 5s"; *)
      Thread.delay 5.;
      retry_econnrefused f
  | e ->
      (* error "Caught %s: does the storage service need restarting?" (Printexc.to_string e); *)
      raise e

module Client = Storage_interface.Client(struct
  let rpc call =
    retry_econnrefused
      (fun () ->
        if !use_switch
        then json_switch_rpc !queue_name call
        else xml_http_rpc
          ~srcstr:(get_user_agent ())
          ~dststr:"storage"
        Storage_interface.uri
        call
      )
end)

let default_vdi_info = {
  vdi = "";
  content_id = "";
  name_label = "";
  name_description = "";
  ty = "user";
  metadata_of_pool = "";
  is_a_snapshot = false;
  snapshot_time = "19700101T00:00:00Z";
  snapshot_of = "";
  read_only = false;
  virtual_size = 0L;
  physical_utilisation = 0L;
  persistent = true;
  sm_config = [];
}
