#!/usr/bin/env python3
"""Talbot run summary, SNP threshold clusters, per-sample core QC and midpoint-rooted tree."""

import argparse
import re
import sys

NO_DATA = 'No data'
NOT_SET = 'Not set'

CORE_MAX_MISSING_PCT = 10.0
MISSING_CHARS = set('-Nn?')

HEADER_SUMMARY = ['pangenome_tool', 'n_genomes', 'core_genes', 'core_alignment_length',
                  'snp_sites', 'min_snp', 'max_snp', 'best_model',
                  'snp_threshold', 'n_clusters', 'core_qc_review']
HEADER_LINKAGE = ['sampleID', 'cluster_id', 'cluster_size', 'closest_sample', 'min_snp',
                  'n_within_threshold']
HEADER_CORE_QC = ['sampleID', 'core_missing_pct', 'core_qc']


def read_matrix(path):
    with open(path) as fh:
        rows = [line.rstrip('\n').split('\t') for line in fh if line.strip()]
    names = rows[0][1:]
    return names, {r[0]: dict(zip(names, map(int, r[1:]))) for r in rows[1:]}


def first_seq_length(path):
    length, seen = 0, False
    with open(path) as fh:
        for line in fh:
            if line.startswith('>'):
                if seen:
                    break
                seen = True
            elif seen:
                length += len(line.strip())
    return length if seen else NO_DATA


def core_genes(path):
    with open(path) as fh:
        for line in fh:
            if line.startswith('Core genes'):
                return line.rstrip('\n').split('\t')[-1].strip()
    return NO_DATA


def best_model(path):
    with open(path) as fh:
        m = re.search(r'Best-fit model according to \w+: (\S+)', fh.read())
    return m.group(1) if m else NO_DATA


def read_fasta(path):
    seqs, name = {}, None
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if line.startswith('>'):
                name = line[1:].split()[0]
                seqs[name] = []
            elif name:
                seqs[name].append(line)
    return {n: ''.join(parts) for n, parts in seqs.items()}


def core_qc_rows(seqs):
    rows = []
    for name, seq in seqs.items():
        pct = round(100 * sum(c in MISSING_CHARS for c in seq) / len(seq), 2) if seq else 100.0
        rows.append([name, pct, 'REVIEW' if pct > CORE_MAX_MISSING_PCT else 'PASS'])
    return rows


def clusters(names, dist, threshold):
    parent = {s: s for s in names}

    def find(s):
        while parent[s] != s:
            parent[s] = parent[parent[s]]
            s = parent[s]
        return s

    for i, a in enumerate(names):
        for b in names[i + 1:]:
            if dist[a][b] <= threshold:
                parent[find(a)] = find(b)

    groups = {}
    for s in names:
        groups.setdefault(find(s), []).append(s)
    linked = sorted((sorted(g) for g in groups.values() if len(g) > 1), key=lambda g: (-len(g), g[0]))
    return {s: (f'cluster_{i}', len(g)) for i, g in enumerate(linked, 1) for s in g}, len(linked)


def linkage_rows(names, dist, threshold, cluster_of):
    rows = []
    for s in names:
        others = {o: d for o, d in dist[s].items() if o != s}
        low = min(others.values())
        closest = sorted(o for o, d in others.items() if d == low)
        cluster_id, size = cluster_of.get(s, ('Unclustered', 1))
        rows.append([s, cluster_id, size, ';'.join(closest), low,
                     sum(d <= threshold for d in others.values())])
    return rows


def write_report(path, header, rows):
    with open(path, 'w', encoding='utf-16', newline='\r\n') as fh:
        fh.write('\t'.join(header) + '\n')
        for row in sorted(rows, key=lambda r: str(r[0])):
            fh.write('\t'.join(str(v).replace(',', ';') for v in row) + '\n')
    print(f"summary_report.py: wrote {path} ({len(rows)} row(s))")


def parse_newick(text):
    s = text.strip().rstrip(';')
    adj, names = {}, {}
    pos = 0

    def read_until(stops):
        nonlocal pos
        start = pos
        while pos < len(s) and s[pos] not in stops:
            pos += 1
        return s[start:pos]

    def node():
        nonlocal pos
        n = len(adj)
        adj[n] = []
        children = []
        if s[pos] == '(':
            while s[pos] != ')':
                pos += 1
                children.append(node())
            pos += 1
        label = read_until(':,)')
        length = 0.0
        if pos < len(s) and s[pos] == ':':
            pos += 1
            length = float(read_until(',)'))
        if not children:
            names[n] = label
        for c, c_len, c_label in children:
            adj[n].append([c, c_len, c_label])
            adj[c].append([n, c_len, c_label])
        return n, length, label if children else ''

    node()
    return adj, names


def distances(adj, start):
    dist, parent, stack = {start: 0.0}, {start: None}, [start]
    while stack:
        u = stack.pop()
        for v, length, _ in adj[u]:
            if v not in dist:
                dist[v] = dist[u] + length
                parent[v] = u
                stack.append(v)
    return dist, parent


def midpoint_root(adj, names):
    leaves = list(names)
    d0, _ = distances(adj, leaves[0])
    a = max(leaves, key=d0.get)
    d, parent = distances(adj, a)
    b = max(leaves, key=d.get)
    half = d[b] / 2

    node = b
    while d[parent[node]] > half:
        node = parent[node]
    p = parent[node]

    edge = next(e for e in adj[p] if e[0] == node)
    length, label = edge[1], edge[2]
    adj[p] = [e for e in adj[p] if e[0] != node]
    adj[node] = [e for e in adj[node] if e[0] != p]

    root = len(adj)
    x = half - d[p]
    adj[root] = [[p, x, label], [node, length - x, label]]
    adj[p].append([root, x, label])
    adj[node].append([root, length - x, label])
    return root


def to_newick(adj, names, node, parent=None, length=None, label=''):
    kids = [e for e in adj[node] if e[0] != parent]
    if kids:
        out = '(' + ','.join(to_newick(adj, names, v, node, l, lab) for v, l, lab in kids) + ')' + label
    else:
        out = names[node]
    return out if length is None else f'{out}:{length:.10g}'


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--matrix',    required=True)
    ap.add_argument('--summary',   required=True)
    ap.add_argument('--core-aln',  required=True)
    ap.add_argument('--snps',      required=True)
    ap.add_argument('--iqtree',    required=True)
    ap.add_argument('--tree',      required=True)
    ap.add_argument('--pangenome', required=True)
    ap.add_argument('--snp-threshold', type=int)
    args = ap.parse_args()

    sys.setrecursionlimit(100000)

    names, dist = read_matrix(args.matrix)
    pairs = [dist[a][b] for a in names for b in names if a != b]

    core_seqs = read_fasta(args.core_aln)
    qc_rows = core_qc_rows(core_seqs)
    write_report('core_qc_report.txt', HEADER_CORE_QC, qc_rows)

    n_clusters = NOT_SET
    if args.snp_threshold is not None:
        cluster_of, n_clusters = clusters(names, dist, args.snp_threshold)
        write_report('linkage_report.txt', HEADER_LINKAGE,
                     linkage_rows(names, dist, args.snp_threshold, cluster_of))

    write_report('summary_report.txt', HEADER_SUMMARY, [[
        args.pangenome, len(names), core_genes(args.summary),
        len(next(iter(core_seqs.values()), '')) or NO_DATA, first_seq_length(args.snps),
        min(pairs), max(pairs), best_model(args.iqtree),
        NOT_SET if args.snp_threshold is None else args.snp_threshold, n_clusters,
        sum(r[2] == 'REVIEW' for r in qc_rows),
    ]])

    with open(args.tree) as fh:
        adj, leaf_names = parse_newick(fh.read())
    root = midpoint_root(adj, leaf_names)
    with open('core_snps.midpoint.treefile', 'w') as fh:
        fh.write(to_newick(adj, leaf_names, root) + ';\n')


if __name__ == '__main__':
    main()
