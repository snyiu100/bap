(** Utility functions for ASTs.  It's useful to have these in a
    separate file so it can use functions from Typecheck and elsewhere. *)

open Ast
open Type

(* exp helpers *)
let binop op a b = match (a,b) with
  | (Int(a, at), Int(b, bt)) when at = bt ->
    let (i,t) = Arithmetic.binop op (a,at) (b,bt) in
    Int(i,t)
  | _ -> BinOp(op, a, b)

let ( +* ) a b   = binop PLUS a b
let ( -* ) a b   = binop MINUS a b
let ( ** ) a b   = binop TIMES a b
let ( <<* ) a b  = binop LSHIFT a b
let ( >>* ) a b  = binop RSHIFT a b
let ( >>>* ) a b = binop ARSHIFT a b
let ( &* ) a b   = binop AND a b
let ( |* ) a b   = binop OR a b
let ( ^* ) a b   = binop XOR a b
let ( ==* ) a b  = binop EQ a b
let ( <* ) a b   = binop LT a b
let ( >* ) a b   = binop LT b a
let ( =* ) a b   = binop XOR a (UnOp(NOT, b))

let cast_low t e = Cast(CAST_LOW, t, e)
let cast_high t e = Cast(CAST_HIGH, t, e)
let cast_signed t e = Cast(CAST_SIGNED, t, e)
let cast_unsigned t = function
  | Cast(CAST_UNSIGNED, Reg t', e) when Arithmetic.bits_of_width t >= t' ->
    Cast(CAST_UNSIGNED, t, e)
  | e ->
    Cast(CAST_UNSIGNED, t, e)

let exp_ite ?t b e1 e2 =
  (* FIXME: were we going to add a native if-then-else thing? *)
  (* type inference shouldn't be needed when t is specified, but we're paranoid *)
  let tb = Typecheck.infer_ast b in
  let t1 = Typecheck.infer_ast e1 in
  let t2 = Typecheck.infer_ast e2 in
  assert (t1 = t2);
  assert (tb = reg_1);

  let t = match t with
    | None -> t1
    | Some t -> assert (t=t1); t
  in
  if t = reg_1 then
    (b &* e1) |*  (exp_not b &* e2)
  else
    ((cast_signed t b) &* e1) |* ((cast_signed t (exp_not b)) &* e2) 

let parse_ite = function
  | BinOp(OR,
	  BinOp(AND, Cast(CAST_SIGNED, _, b1), e1),
	  BinOp(AND, Cast(CAST_SIGNED, _, UnOp(NOT, b2)), e2)
  ) 
  | BinOp(OR,
	  BinOp(AND, b1, e1),
	  BinOp(AND, UnOp(NOT, b2), e2)
  ) when b1 = b2 && Typecheck.infer_ast ~check:false b1 = reg_1-> 
    Some(b1, e1, e2)
      (* In case one branch is optimized away *)
  | BinOp(AND,
	  Cast(CAST_SIGNED, nt, b1),
	  e1) when Typecheck.infer_ast ~check:false b1 = reg_1 ->
    Some(b1, e1, Int(0L, nt))
  | _ -> None
