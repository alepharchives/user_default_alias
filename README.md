# user_default_alias

Commands can be added to the Erlang shell by creating a module named
`user_default`. `user_default_alias` constructs a `user_default` module from
an existing module. This makes it easy to preserve
[your own](https://github.com/andrewtj/erlang_user_utilities) commands during
development and have an application specific set available in production.

Example use:

```
Erlang R14B03 (erts-5.8.4) [source] [64-bit] [smp:2:2] [rq:2] [async-threads:0] [hipe] [kernel-poll:false]

Eshell V5.8.4  (abort with ^G)
1> reverse([1,2,3]).
** exception error: undefined shell command reverse/1
2> user_default_alias:from(lists).
ok
3> reverse([1,2,3]).
[3,2,1]
```

If a user_default module already exists and is not generated from the same
module `{error,exists}` will be returned. This check can be overridden:

```
4> user_default_alias:from(dict).
{error,exists}
5> user_default_alias:from(dict,true).
ok
6> to_list(new()).
[]
7> user_default_alias:from(dict)
ok
```