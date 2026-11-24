# Visual Pattern Mining Analysis

Images and transactions: 1360.

- Minsup 0.7: 11 frequent itemsets.
- Minsup 0.8: 0 frequent itemsets.
- Minsup 0.9: 0 frequent itemsets.

Images containing all 16 visual words: 8/1360 (0.59%).
Average visual words per image: 11.38.
High saturation can reduce the ability of patterns to distinguish images. Compare a larger K or fewer descriptors on the same images.
Each pattern can be used as a binary feature for classification or image retrieval. Evaluate on an independent test set before drawing conclusions.

ORB describes local image regions. Visual words are descriptor clusters, not necessarily specific flower parts.
Transactions discard spatial positions and repetitions. K, seed and image size affect results; co-occurrence does not establish classification performance.
