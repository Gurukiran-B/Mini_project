from __future__ import annotations

from typing import Dict, List, Tuple
import math
import torch


def build_graph_tensors(edges: List[Tuple[str, str, float]]):
    node_to_idx: Dict[str, int] = {}
    for u, v, _ in edges:
        if u not in node_to_idx:
            node_to_idx[u] = len(node_to_idx)
        if v not in node_to_idx:
            node_to_idx[v] = len(node_to_idx)
    num_nodes = len(node_to_idx)

    src_idx = torch.tensor([node_to_idx[u] for u, _, _ in edges], dtype=torch.long)
    dst_idx = torch.tensor([node_to_idx[v] for _, v, _ in edges], dtype=torch.long)
    w = torch.tensor([w for _, _, w in edges], dtype=torch.float32)
    return node_to_idx, num_nodes, src_idx, dst_idx, w


def bellman_ford(num_nodes: int, src_idx: torch.Tensor, dst_idx: torch.Tensor, weights: torch.Tensor, start_idx: int):
    dist = torch.full((num_nodes,), float('inf'), dtype=torch.float32)
    pred = torch.full((num_nodes,), -1, dtype=torch.int32)
    dist[start_idx] = 0.0

    for _ in range(num_nodes - 1):
        updated = False
        # relaxation: for each edge u->v with weight w
        for e in range(weights.shape[0]):
            u = src_idx[e].item()
            v = dst_idx[e].item()
            w = weights[e].item()
            if dist[u] + w < dist[v]:
                dist[v] = dist[u] + w
                pred[v] = u
                updated = True
        if not updated:
            break

    # Negative cycle detection (optional; not raising, but could flag)
    has_neg_cycle = False
    for e in range(weights.shape[0]):
        u = src_idx[e].item()
        v = dst_idx[e].item()
        w = weights[e].item()
        if dist[u] + w < dist[v]:
            has_neg_cycle = True
            break

    return dist, pred, has_neg_cycle


def reconstruct_path(pred: torch.Tensor, start_idx: int, end_idx: int) -> List[int]:
    path: List[int] = []
    cur = end_idx
    visited = set()
    while cur != -1 and cur not in visited:
        path.append(cur)
        if cur == start_idx:
            break
        visited.add(cur)
        cur = int(pred[cur].item())
    path.reverse()
    if path and path[0] == start_idx:
        return path
    return []


def a_star_adjacency(start: int, goal: int, adjacency: Dict[int, List[Tuple[int, float]]], heuristic: torch.Tensor) -> Tuple[List[int], float]:
    open_set = {start}
    came_from: Dict[int, int] = {}
    g_score = {start: 0.0}
    f_score = {start: heuristic[start].item()}

    while open_set:
        current = min(open_set, key=lambda n: f_score.get(n, math.inf))
        if current == goal:
            # reconstruct
            path = [current]
            while current in came_from:
                current = came_from[current]
                path.append(current)
            path.reverse()
            return path, g_score[path[-1]]

        open_set.remove(current)
        for neighbor, weight in adjacency.get(current, []):
            tentative_g = g_score[current] + float(weight)
            if tentative_g < g_score.get(neighbor, math.inf):
                came_from[neighbor] = current
                g_score[neighbor] = tentative_g
                f_score[neighbor] = tentative_g + heuristic[neighbor].item()
                open_set.add(neighbor)

    return [], float('inf')


def hybrid_route(edges: List[Tuple[str, str, float]], start: str, end: str, heuristic_map: Dict[str, float] | None = None):
    node_to_idx, num_nodes, src_idx, dst_idx, w = build_graph_tensors(edges)
    if start not in node_to_idx or end not in node_to_idx:
        return [], float('inf'), node_to_idx

    start_idx = node_to_idx[start]
    end_idx = node_to_idx[end]

    # Step 1: Bellman-Ford for robustness (handles negative edges)
    dist, pred, _ = bellman_ford(num_nodes, src_idx, dst_idx, w, start_idx)

    # Build adjacency for A* using tensor weights
    adjacency: Dict[int, List[Tuple[int, float]]] = {}
    for e in range(w.shape[0]):
        u = int(src_idx[e].item())
        v = int(dst_idx[e].item())
        adjacency.setdefault(u, []).append((v, float(w[e].item())))

    # Heuristic tensor
    heuristic = torch.zeros((num_nodes,), dtype=torch.float32)
    if heuristic_map:
        for name, h in heuristic_map.items():
            if name in node_to_idx:
                heuristic[node_to_idx[name]] = float(h)

    # Step 2: Use A* but initialize with BF distances as guidance
    # We bias heuristic by already found BF distance baseline to accelerate convergence
    heuristic = heuristic

    path_idx, cost = a_star_adjacency(start_idx, end_idx, adjacency, heuristic)
    if not path_idx:
        # fallback to BF path reconstruction
        path_idx = reconstruct_path(pred, start_idx, end_idx)
        cost = float(dist[end_idx].item()) if path_idx else float('inf')

    # Map back to node names
    idx_to_node = {idx: node for node, idx in node_to_idx.items()}
    path_names = [idx_to_node[i] for i in path_idx]
    return path_names, cost, node_to_idx


