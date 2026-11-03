"""Turns the CIFAR-10 Parquet files from Hugging Face into two NumPy files that train_ddp.py loads.

    python prepare_cifar10.py <folder>    # reads <folder>/{train,test}.parquet, writes <folder>/{train,test}.npz

The images are stored as PNG (lossless), so the pixels are the same as in the original release.
"""

import io
import sys
from pathlib import Path

import numpy as np
import pyarrow.parquet as pq
from PIL import Image

folder = Path(sys.argv[1])
for split in ("train", "test"):
    table = pq.read_table(folder / f"{split}.parquet", columns=["img", "label"])
    images = np.stack([np.asarray(Image.open(io.BytesIO(img["bytes"])).convert("RGB"))
                       for img in table.column("img").to_pylist()])
    labels = np.asarray(table.column("label").to_pylist(), dtype=np.int64)
    tmp = folder / f"{split}.tmp.npz"
    np.savez(tmp, images=images, labels=labels)  # images: N × 32 × 32 × 3, uint8
    tmp.rename(folder / f"{split}.npz")
    print(f"{split}: {len(labels)} images", flush=True)
