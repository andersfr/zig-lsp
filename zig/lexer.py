#!/usr/bin/env python2.7

import re
import sys
import string

def regex_mod(m,s):
    if m == '':
        return s
    elif m == '?':
        return regex_or(regex_epsilon(), s)
    return (m,s)

def regex_squares(s):
    if s == '':
        raise ValueError("empty []")

    cs = []
    n = False
    if s[0] == '^':
        n = True
        s = s[1:]

    i = 0
    e = len(s)

    while(i < e):
        if i + 2 < e and s[i+1] == '-':
            ca = ord(s[i])
            cb = ord(s[i+2])
            for cx in range(ca,cb+1):
                cs.append(chr(cx))
            i = i + 3
        else:
            cs.append(s[i])
            i = i + 1

    if n:
        cn = []
        for o in range(128):
            if not chr(o) in cs:
                cn.append(chr(o))
        return ('[]', cn)

    return ('[]', cs)

def regex_or(a,b):
    return ('|', a, b)

def regex_and(a,b):
    return ('&', a, b)

def regex_seq(s):
    if s == '':
        return regex_epsilon()
    return ('s', s)

def regex_epsilon():
    return ('e',)

def regex_parse(s):
    if s == '':
        return regex_epsilon()

    il = 0
    while True:
        il = s.find('|', il) + 1
        if il == 0:
            break
        if il > 1 and s[il-2] == '\\':
            continue
        ls, rs = s[:il-1],s[il:]

        # check if embedded in parantheses
        oc = 0
        cc = 0
        ec = False
        for c in ls:
            if not ec and (c == '(' or c == '['):
                oc += 1
            elif not ec and (c == ')' or c == ']'):
                cc += 1
            elif not ec and c == '\\':
                ec = True
            else:
                ec = False

        if oc != cc:
            continue

        return regex_or(regex_parse(ls), regex_parse(rs))

    for m in [ ('(', ')', regex_parse), ('[',']', regex_squares) ]:
        il = 0
        while True:
            il = s.find(m[0], il) + 1
            if il == 0:
                break
            if il > 1 and s[il-2] == '\\':
                continue
            ir = s.find(m[1], il)
            if ir == -1:
                err = "mismatched " + m[0] + m[1]
                raise ValueError(err)

            ls, ms, rs = s[:il-1], s[il:ir], s[ir+1:]
            mod = ''
            if rs != '':
                for x in ['*','+','?']:
                    if rs[0] == x:
                        rs = rs[1:]
                        mod = x
                        break

            return regex_and(regex_parse(ls), regex_and(regex_mod(mod,m[2](ms)), regex_parse(rs)))

    ls = ''
    i = 0
    e = len(s)
    while(i < e):
        c = s[i]
        i = i + 1
        if c == '\\':
            c = s[i]
            i = i + 1
            if c == 't':
                c = '\t'
            elif c == 'r':
                c = '\r'
            elif c == 'n':
                c = '\n'
            ls += c
        elif c == '.':
            return regex_and(regex_seq(ls), regex_and(regex_squares('^'), regex_parse(s[i:])))
        elif c in ['?','*','+']:
            if ls == '':
                raise ValueError('unattached \''+c+'\'')
            lc = ls[-1]
            ls = ls[:-1]
            return regex_and(regex_seq(ls), regex_and(regex_mod(c,lc), regex_parse(s[i:])))
        else:
            ls += c

    return regex_seq(ls)

def regex_simplify(r):
    if r[0] == '&':
        if r[1][0] == 'e':
            return regex_simplify(r[2])
        if r[2][0] == 'e':
            return regex_simplify(r[1])

    if r[0] == '&' or r[0] == '|':
        return (r[0], regex_simplify(r[1]), regex_simplify(r[2]))

    if r[0] == '*':
        return (r[0], regex_simplify(r[1]))

    return r

def regex_init(s):
    return regex_simplify(regex_parse(s))

def nfa_parse(t, r, t_in, t_out):
    if r[0] == 'e':
        t[t_in][1].append( t_out )
    elif r[0] == '|':
        nfa_parse(t, r[1], t_in, t_out)
        nfa_parse(t, r[2], t_in, t_out)
    else:
        s = len(t)
        t.append( ([],[0]*128) )
        t[s][1].append(s)

        if r[0] == '*' or r[0] == '+':
            t[t_in][1].append( s )
            if r[0] == '*':
                t[s][1].append( t_out )

            s2 = len(t)
            t.append( ([],[0]*128) )
            t[s2][1].append(s2)
            t[s2][1].append(s)
            t[s2][1].append(t_out)

            nfa_parse(t, r[1], s, s2)
        elif r[0] == '&':
            nfa_parse(t, r[1], t_in, s)
            nfa_parse(t, r[2], s, t_out)
        elif r[0] == '[]':
            t[t_in][1].append( s )
            for c in r[1]:
                t[s][1][ord(c)] = t_out
        elif r[0] == 's':
            t[t_in][1].append( s )
            for c in r[1][:-1]:
                t[s][1][ord(c)] = s+1
                s = s + 1
                t.append( ([],[0]*128) )
                t[s][1].append(s)
            t[s][1][ord(r[1][-1])] = t_out

def nfa_eps_closures(t):
    eps = dict()
    eps2 = []

    for i,s in enumerate(t):
        e = s[1][128:]
        j = 1
        while(j < len(e)):
            ex = t[e[j]][1][128:]
            j = j + 1
            for x in ex:
                if not x in e:
                    e.append(x)
        e = sorted(e)
        eps[str(e)] = e
        eps2.append(e)

    return (eps,eps2)

def nfa_eps_collapse(t, t2, ecs, ecs2, sm, start):
    if start in sm:
        return

    no = len(t2)
    t2.append( ([],[0]*129) )
    t2[no][1][128] = no

    sm[start] = no

    if not start in ecs:
        ecs[start] = map(int, start[1:-1].split(', '))

    for row in ecs[start]:
        for ts in t[row][0]:
            t2[no][0].append(ts)
        for i in range(128):
            v = t[row][1][i]
            if v == 0:
                continue
            if t2[no][1][i] == 0:
                t2[no][1][i] = [v]
            else:
                t2[no][1][i].append(v)

    for i in range(128):
        v = t2[no][1][i]
        if v != 0:
            va = []
            for x in v:
                for y in ecs2[x]:
                    va.append(y)
            va = sorted(list(set(va)))
            nfa_eps_collapse(t, t2, ecs, ecs2, sm, str(va))
            t2[no][1][i] = sm[str(va)]

def nfa_init(accept,r):
    t = []
    t.append( ([], [ 0 ] * 129) )
    t.append( ([accept], [ 0 ] * 129) )
    t[1][1][128] = 1

    nfa_parse(t, r, 0, 1)

    return t

def dfa_init(nfa):
    ecs, ecs2 = nfa_eps_closures(nfa)
    sm = dict()
    dfa = []
    nfa_eps_collapse(nfa, dfa, ecs, ecs2, sm, str(ecs2[0]))
    for row in range(len(dfa)):
        if len(dfa[row][0]) > 0:
            dfa[row] = ([min(dfa[row][0])], dfa[row][1])

    return dfa

def dfa_combine(dfas):
    t = []
    t.append( ([], [ 0 ] * 129) )
    for dfa in dfas:
        offs = len(t)
        t[0][1].append( offs )
        for i, row in enumerate(dfa):
            t.append( row )
            for v in range(len(t[offs+i][1])):
                x = t[offs+i][1][v]
                if x > 0 or (i == 0 and v == 128):
                    t[offs+i][1][v] += offs

    return dfa_init(t)

def dfa_simplify(dfa):
    m = dict()
    m2 = dict()
    r = []
    s = len(dfa)
    for i in range(s):
        for j in range(i+1,s):
            if dfa[i][0] != dfa[j][0]:
                continue
            ok = True
            for c in range(128):
                if dfa[i][1][c] != dfa[j][1][c]:
                    ok = False
                    break
            if ok:
                m2[j] = i
                r.append(j)

    v = 0
    for i in range(s):
        if not i in r:
            m[i] = v
            v += 1
    for k,x in m2.iteritems():
        if x <= 0:
            m[k] = x
        else:
            m[k] = m[x]

    for i in sorted(r, reverse=True):
        del dfa[i]

    s = len(dfa)
    for i in range(s):
        for c in range(len(dfa[i][1])):
            dfa[i][1][c] = m[dfa[i][1][c]]

    m = dict()
    m2 = dict()
    r = []
    for i in range(s):
        ok = True
        for c in range(128):
            if dfa[i][1][c] != 0:
                ok = False
                break
        if ok:
            r.append(i)
            m2[i] = -dfa[i][0][0]

    v = 0
    for i in range(s):
        if not i in r:
            m[i] = v
            v += 1
    for k,x in m2.iteritems():
        if x <= 0:
            m[k] = x
        else:
            m[k] = m[x]

    for i in sorted(r, reverse=True):
        del dfa[i]

    s = len(dfa)
    for i in range(s):
        for c in range(128):
            dfa[i][1][c] = m[dfa[i][1][c]]
        del dfa[i][1][128:]

    return dfa

def dfa_compress(dfa):
    C = 128
    N = len(dfa)
    tc = [ ([0], [ 'E' ] * C) ]
    for c in range(C):
        tc[0][1][c] = dfa[0][1][c]
    for n in range(1,N):
        if len(dfa[n][0]) == 0:
            tc.append(([0], ['E']*C))
        else:
            tc.append((dfa[n][0], ['E']*C))
    for c in range(C):
        sc = dfa[0][1][c]
        if sc <= 0:
            continue
        for y in range(C):
            if 0 != dfa[sc][1][y]:
                tc[sc][1][y] = dfa[sc][1][y]
            elif tc[sc][1][y] == 'E':
                tc[sc][1][y] = 'X'
    for sp in range(1,N):
        for c in range(C):
            sc = dfa[sp][1][c]
            if sc <= 0:
                continue
            for y in range(C):
                if dfa[sp][1][y] != dfa[sc][1][y]:
                    tc[sc][1][y] = dfa[sc][1][y]
                elif tc[sc][1][y] == 'E':
                    tc[sc][1][y] = 'X'

    for n in range(1,N):
        i = 0
        e = C
        rle = []
        while(i < e):
            if tc[n][1][i] == 'X':
                i += 1
                continue
            v = dfa[n][1][i]
            s = i
            i += 1
            c = 0
            while(i < e and tc[n][1][i] == v):
                i += 1
                c += 1
            rle.append((s,s+c,v))

        tc[n] = (tc[n][0], rle)

    m = dict()
    s = len(tc)
    for c in range(C):
        v = tc[0][1][c]
        if v < 0:
            if not v in m:
                m[v] = s
                s += 1
            tc[0][1][c] = m[v]
    wst = m

    m = dict()
    for n in range(1,N):
        for r in range(len(tc[n][1])):
            v = tc[n][1][r][2]
            if v < 0:
                if not v in m:
                    m[v] = s
                    s += 1
                tc[n][1][r] = (tc[n][1][r][0], tc[n][1][r][1], m[v])

    rm = dict()
    for k in wst.iterkeys():
        rm[wst[k]] = -k
    for k in m.iterkeys():
        rm[m[k]] = -k

    wst = (wst,m,rm)

    return (tc,wst)

def main():
    if len(sys.argv) != 2:
        print "Usage: " + sys.argv[0] + " <input.ll.cc>"
        sys.exit(1)

    lines = []
    if sys.argv[1] == '-':
        lines = sys.stdin.readlines()
    else:
        with open(sys.argv[1], 'r') as f:
            lines = f.readlines()

    output = []
    tests = []
    dfas = []

    tokens = set()
    symbols = set()
    br = re.compile('.*//\\s*%(missing|token)\\s+([A-Za-z0-9_]+).*')
    sr = re.compile('\\s*//\\s*%symbols\\s+([^ \\t\\r\\n]+)')
    for line in lines:
        m = br.match(line)
        if m != None:
            tokens.add(m.groups(1)[1])
        m = sr.match(line)
        if m != None:
            for s in m.groups(1)[0]:
                symbols.add(s)

    symbols = map(ord, symbols)
    tokens = list(tokens)
    tokens.sort()
    token_id = dict()
    token_id_rev = dict()
    token_id["Invalid"] = 0
    token_id_rev[0] = "Invalid"
    token_id_next = 1
    for token in tokens:
        while token_id_next in symbols:
            token_id_next += 1
        token_id[token] = token_id_next
        token_id_rev[token_id_next] = token
        token_id_next += 1

    output.append("const Lexer = @import(\"zig_lexer.zig\").Lexer;\n")
    output.append("pub const Id = @import(\"zig_grammar.tokens.zig\").Id;\n\n")
    # output.append("pub const Id = enum(u8) {\n")
    # for (k,v) in token_id_rev.iteritems():
    #     output.append('    ' + v + ' = ' + str(k) + ",\n")
    # output.append("  };\n")

    rx = re.compile('\\s*//\\s*(?:%token\\s+([^ \\t%]+)\\s+)?%dfa\\s+([^ \\t\\r\\n].*)')
    ri = re.compile('\\s*//\\s*%ignore')
    rt = re.compile('\\s*//\\s*%end')
    rc = re.compile('\\s*//')
    l = 0
    e = len(lines)
    while(l < e):
        line = lines[l]

        if ri.match(line):
            while(l < e):
                l += 1
                if rt.match(lines[l]):
                    break
            l += 1
            continue

        m = rx.match(line)
        if m == None:
            if line.rstrip() != '':
                output.append(line)
            l += 1
            continue
        token,dfa = m.groups(1)
        dfa = dfa.rstrip()
        if token == 1:
            token = None

        comments = ''
        while(len(output) > 0 and rc.match(output[-1])):
            comments += output[-1].lstrip()
            del output[-1]
        comments += line.lstrip()
        code = ''
        if token == None:
            while(l < e):
                l += 1
                if rt.match(lines[l]):
                    break
                code += lines[l]
        l += 1
        dfas.append((dfa,comments.rstrip(),code.rstrip(),token))
        if (token != None):
            tests.append("test \"%s\" {" % dfa.replace('\\',''))
            tests.append("    try testToken(\"%s\", Token.Id.%s);" % (dfa.replace('\\', ''), token))
            tests.append("}")

    dfa = dfa_simplify(dfa_combine(map(lambda (i,dfa): dfa_init(nfa_init(i+1, regex_init(dfa[0]))), enumerate(dfas))))
    dfc,wst = dfa_compress(dfa)

    # print '\n'.join(tests)
    # for i,s in enumerate(dfc):
    #     print (i,s[0], s[1])

    output.append('\n')

    # begin init state
    output.append('pub const init_state align(64) = [128]u16{')
    for c in range(128):
        output.append(str(dfc[0][1][c]))
        if c < 127:
            output.append(', ')
    output.append('};\n\n')
    # end init state

    # begin accept states
    output.append('pub const accept_states = ['+str(len(dfc)+len(wst[2]))+']u8{')
    output.append('0')
    for s in range(1,len(dfc)):
        output.append(', '+str(dfc[s][0][0]))
    for k in sorted(wst[2].iterkeys()):
        output.append(', '+str(wst[2][k]))
    output.append('};\n\n')
    # end accept states

    # begin rle states
    rle = []
    cnt = 0
    output.append('pub const rle_states = [_]u16{')
    for s in range(1,len(dfc)):
        rle.append(cnt)
        for r in dfc[s][1]:
            output.append(str(r[0])+', '+str(r[1])+', '+str(r[2])+', ')
            cnt += 3
        output.append('65535, ')
        cnt += 1

    rle_wipe = cnt
    rle_none = cnt + 3

    output.append('0, 127, 0, 65535, 0, 0};\n\n')
    # end rle states

    # begin rle indices
    output.append('pub const rle_indices = ['+str(len(rle)+len(wst[0])+len(wst[1])+1)+']u16{')
    output.append('65535')
    for r in rle:
        output.append(', '+str(r))
    for w in wst[1]:
        output.append(', '+str(rle_wipe))
    for w in wst[0]:
        output.append(', '+str(rle_none))
    output.append('};\n\n')
    # end rle indices

    # begin tokens
    tokens = 0
    output.append('pub const accept_tokens = [_]Id{')
    output.append('.Invalid')
    for dfa in dfas:
        if dfa[3] != None:
            output.append(', .'+dfa[3])
            tokens += 1
    output.append('};\n\n')
    # end tokens

    # begin yyswitch
    output.append('pub fn lexer_switch( self: *Lexer, accept: u8 ) Id {\n')
    output.append('  switch (accept) {\n')
    for i,dfa in enumerate(dfas):
        if dfa[3] == None:
            output.append(' '+str(i-tokens)+' => \n')
            output.append(dfa[1])
            output.append('\n')
            output.append(dfa[2])
            output.append(',\n')
    output.append('else => unreachable,\n')
    output.append('}\n')
    output.append('return .Invalid;\n')
    output.append('}')
    # end yyswitch

    with open('zig_lexer.tab.zig', 'w') as f:
        for line in output:
            f.write(line)


main()

# for i,s in enumerate(dfa):
#     print (i,s[0], s[1])

# for i,dfa in enumerate(dfas):
#     print (i+1,dfa[1])
