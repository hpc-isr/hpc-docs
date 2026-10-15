# Diagrams

[← Overview](../README.md)

Each diagram is a Mermaid source file here, rendered to an SVG in `overview/img/` ([network](../img/network.svg), [shared node](../img/node-shared.svg), [group node](../img/node-group.svg)) that the pages embed.

| Source | Image | Used in |
|---|---|---|
| [network.mmd](network.mmd) | [network.svg](../img/network.svg) | [Network](../network.md) |
| [node-shared.mmd](node-shared.mmd) | [node-shared.svg](../img/node-shared.svg) | [Inside a node](../node-anatomy.md) |
| [node-group.mmd](node-group.mmd) | [node-group.svg](../img/node-group.svg) | [Inside a node](../node-anatomy.md) |

The `hpc-dsor` diagram lives with its group guide, which is not yet published.

## Style

All three diagrams share one look: a light theme with a sans-serif font, rounded boxes and soft colours by role.

| Colour | Meaning |
|---|---|
| Blue | Shared SLURM cluster, MooseFS |
| Green | Group nodes |
| Amber | Storage outside the filesystem layer (CEPH volumes, NVMe) |
| Grey | Entry points and plain mount points |
| Dashed grey | Not in use or not yet documented |

The colours are `classDef` lines at the end of each `.mmd` file; the theme is in [mermaid-config.json](mermaid-config.json) and repeated in each file's front matter, so <https://mermaid.live> shows the same style.

## Re-render after editing

With Node.js installed (any machine):

```bash
cd hpc-kb/overview
for n in network node-shared node-group; do
  npx -y -p @mermaid-js/mermaid-cli@11.4.2 mmdc -c diagrams/mermaid-config.json -b white \
    -i diagrams/$n.mmd -o img/$n.svg
done
```

`htmlLabels: false` makes the SVG use plain text labels, so it displays in any viewer (browsers, GitHub), not only ones that support HTML inside SVG.

You can also paste a `.mmd` file into <https://mermaid.live> to edit it visually and export an SVG.
