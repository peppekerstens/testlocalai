This setting decides how stand-in values are created. There are two choices.

With consistent mode, the same real value always gets the same token. This
happens every time, in every request, during a session. Because of that, you
can treat two tokens as the same record. You can safely compare results
across two different requests.

With session-random mode, the same real value gets a brand-new token on
every single request. This happens even within one session. Two tokens can
never be assumed to be the same record. You can only match tokens across
requests when the mode is consistent.
