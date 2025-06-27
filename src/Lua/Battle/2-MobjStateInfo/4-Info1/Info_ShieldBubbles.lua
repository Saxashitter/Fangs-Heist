states[S_ARMA1] = {SPR_ARMA, FF_ANIMATE|FF_TRANS50|A, -1, nil, 15, 2, S_NULL}

states[S_WIND1] = {SPR_WIND, FF_ANIMATE|FF_TRANS60|A, -1, nil, 7, 2, S_NULL}

states[S_MAGN1] = {SPR_MAGN, FF_ANIMATE|FF_TRANS50|A, -1, nil, 11, 2, S_NULL}

states[S_FORC1] = {SPR_FORC, FF_ANIMATE|FF_TRANS60|A, -1, nil, 9, 3, S_FORC1}//Full force shield

states[S_FORC11] = {SPR_FORC, FF_ANIMATE|FF_TRANS60|K, 9, nil, 9, 3, S_FORC12}//Half force shield, pulsate effect
states[S_FORC12] = {SPR_FORC, FF_ANIMATE|FF_TRANS70|K, 9, nil, 9, 3, S_FORC13}
states[S_FORC13] = {SPR_FORC, FF_ANIMATE|FF_TRANS80|K, 9, nil, 9, 3, S_FORC14}
states[S_FORC14] = {SPR_FORC, FF_ANIMATE|FF_TRANS70|K, 9, nil, 9, 3, S_FORC11}

states[S_ELEM1] = {SPR_ELEM, FF_ANIMATE|FF_TRANS60|A, -1, nil, 11, 4, S_NULL}
states[S_ELEMF1] = {SPR_ELEM, FF_FULLBRIGHT|FF_ANIMATE|FF_TRANS50|M, -1, nil, 7, 3, S_NULL}

states[S_PITY1] = {SPR_PITY, FF_ANIMATE|FF_TRANS50|A, -1, nil, 11, 2, S_NULL}
