%% -------------------------------------------------------------------
%%
%% Copyright (c) 2011 Andrew Tunnell-Jones. All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------
-module(user_default_alias).
-export([from/1, from/2]).

%% @equiv from(Mod, false)
-spec from(Module :: atom()) -> ok | {error, exists}.
from(Module) when is_atom(Module) -> from(Module, false).

%% @doc Create and load a user_default module from an existing module.
%%      When Replace is {@type false}, if a user_default module is already
%%      loaded and is not generated from the same module
%%      {@type {error,exists@}} will be returned. Returns {@type ok} otherwise.
-spec from(Module :: atom(), Replace :: boolean()) -> ok | {error, exists}.
from(Module, Replace) when is_atom(Module) andalso is_boolean(Replace) ->
    File = ?MODULE_STRING ":" ++ atom_to_list(Module),
    case code:is_loaded(user_default) of
	{file, Other} when File /= Other andalso not Replace -> {error, exists};
	_ -> build_module(File, Module)
    end.

build_module(File, Module) ->
    Exports = exports(Module),
    Tokens = build_tokens(Module, Exports),
    Forms = build_forms(Tokens),
    {ok, user_default, Bin} = compile:forms(Forms),
    code:purge(user_default),
    {module, user_default} = code:load_binary(user_default, File, Bin),
    ok.

exports(M) -> [ X || {F, _A} = X <- M:module_info(exports), F =/= module_info ].

build_tokens(M, E) -> module_tokens() ++ export_tokens(E) ++ fun_tokens(M, E).

module_tokens() -> [ tokens_from_string("-module(user_default).") ].

export_tokens(Exports) -> [ export_token(Export) || Export <- Exports ].

export_token({F, A}) ->
    tokens_from_string("-export([" ++ as_list(F) ++ "/" ++ as_list(A) ++ "]).").

fun_tokens(Module, Exports) -> [ fun_token(Module, X) || X <- Exports ].

fun_token(Module, {F, A}) ->
    Fun = as_list(F),
    ModuleList = as_list(Module),
    Args = string:join(["A" ++ as_list(N) || N <- lists:seq(1, A) ], ","),
    FunArgs = Fun ++ "(" ++ Args ++ ")",
    String = FunArgs ++ " -> " ++ ModuleList ++ ":" ++ FunArgs ++ ".",
    tokens_from_string(String).

tokens_from_string(String) -> {ok, Tokens, _} = erl_scan:string(String), Tokens.

build_forms(Tokens) -> [ build_form(Token) || Token <- Tokens ].

build_form(Token) -> {ok, Form} = erl_parse:parse_form(Token), Form.

as_list(Atom) when is_atom(Atom) -> atom_to_list(Atom);
as_list(Int) when is_integer(Int) -> integer_to_list(Int).
