# Parsing captions and get chunk phrases out of them

## parsing dataset for extracting chunks

After pre-processing, data is organized as follows in _output_dir_:
```
output_dir/
  sentences.txt              # raw captions
  sentences.token            # tokenized captions
  sentences.final            # normalized captions
  sentences.chk              # chunk tags (output from SENNA)
  sentences.chksz            # reformatted chunk tags (one caption per line)
  sentences.chkszfinal       # normalized chunk tags
  nb.txt                     # number of captions per image
  id.txt                     # image ids
  vocab/
    NP.txt                   # noun phrase vocabulary
    VP.txt                   # verbal phrase vocabulary
    PP.txt                   # prepositional phrase vocabulary
  text/
    image_NP_ge10.txt        # noun phrases from image captions
    image_NP_ge10.index      # same as above, but with indices (for training purpose)
    image_VP_ge10.txt        # verbal phrases from image captions
    image_VP_ge10.index      # same as above, but with indices (for training purpose)
    image_PP_ge10.txt        # prepositional phrases from image captions
    image_PP_ge10.index      # same as above, but with indices (for training purpose)
    image_START-NP_ge10.txt  # noun phrases from starting image captions
    image_NP_ge10.txt  # noun phrases from starting image captions
    image_START-NP_ge10.txt  # starting noun phrases from image captions
    image_NP-PP_ge10.txt     # noun-prepositional pair phrases from image captions
    image_NP-VP_ge10.txt     # noun-verbal pair phrases from image captions
    image_PP-NP_ge10.txt     # prepositional-noun pair phrases from image captions
    image_VP-NP_ge10.txt     # verbal-noun pair phrases from image captions
    image_NP-PERIOD_ge10.txt # ending noun phrases from image captions
  proba/
    NP_given_START_ge10.txt  # noun phrases probabilities for starting captions
    PP_given_NP_ge10.txt     # prepositional phrases probabilities given a noun phrase
    VP_given_NP_ge10.txt     # verbal phrases probabilities given a noun phrase
    NP_given_VP_ge10.txt     # noun phrases probabilities given a verbal phrase
    NP_given_PP_ge10.txt     # noun phrases probabilities given a prepositional phrase
    CHK_given_NP_ge10.txt    # type of phrases probabilities given noun phrase type
  image/
    features.bin             # 2D torch.FloatTensor object with image features
    id.txt                   # image ids
  lookup/
    NP_400d_ge10.bin         # 400d noun phrase embeddings (2D torch.FloatTensor)
    VP_400d_ge10.bin         # 400d verbal phrase embeddings (2D torch.FloatTensor)
    PP_400d_ge10.bin         # 400d prepositional phrase embeddings (2D torch.FloatTensor)
```
In this example, we consider only phrases that appear at least 10 times in the
training dataset.

### parse input file
This step assumes that each input line contains the image id in first column,
then image captions in the next columns. Each column is separated by tabulation
character.
```
lua chunking/parse.lua "$input_file" "$output_dir"
```

### tokenize sentence
With Stanford tokenizer.
```
java -cp third_party/stanford-parser.jar \
  edu.stanford.nlp.process.PTBTokenizer \
  -preserveLines "$output_dir/sentences.txt" \
  > "$output_dir/sentences.token"
```

### normalize token for SENNA
Preparing text data for chunking with SENNA.
```
lua chunking/normalize_token.lua "$output_dir"
```

### do chunking with SENNA
```
cd third_party/senna
senna \
  -usrtokens \
  -chk \
  -notokentags \
  -brackettags \
  < "$output_dir/sentences.final" \
  > "$output_dir/sentences.chk"
cd ../..
```

### get chunk size
```
lua chunking/chunksize.lua "$output_dir"
```

### normalize phrases
Merging some phrases into longer verbal phrases or prepositional phrases.
```
lua chunking/normalize_phrases.lua "$output_dir"
```

## building vocabularies for phrases

### get noun phrases, verbal phrases and prepositional phrases
```
mkdir vocab
lua phrases/get_phrases.lua "NP" "$output_dir"
lua phrases/get_phrases.lua "VP" "$output_dir"
lua phrases/get_phrases.lua "PP" "$output_dir"
```

### associate phrases with images
Here a threshold can be set to remove rare phrases, and reduce the vocabulary
size at the same time.
```
lua phrases/image_phrases.lua "NP" "$output_dir" 10
lua phrases/image_phrases.lua "VP" "$output_dir" 10
lua phrases/image_phrases.lua "PP" "$output_dir" 10
```


## getting transition probabilities between phrases

### get pairs of phrases from image captions
```
cd lm
lua phrases_pairs.lua "$output_dir" 10
cd ..
```

### get transition probabilities between phrases
```
cd lm
th transition-proba.lua "$output_dir" 10
cd ..
```

### get vocabularies for phrase pairs
```
cd lm
lua vocab-biphrase.lua "$output_dir" 10
cd ..
```

### get transition probabilities between phrase pairs
```
cd lm
th transition-proba-biphrase.lua "$output_dir" 10 NP-PP NP
th transition-proba-biphrase.lua "$output_dir" 10 NP-VP NP
th transition-proba-biphrase.lua "$output_dir" 10 PP-NP VP
th transition-proba-biphrase.lua "$output_dir" 10 VP-NP VP
th transition-proba-biphrase.lua "$output_dir" 10 PP-NP PP
th transition-proba-biphrase.lua "$output_dir" 10 VP-NP PP
cd ..
```

# Training a bilinear model for learning metric between images and phrases

## get phrase embeddings
This step assumes that word embeddings have been computed beforehand.
Word embeddings are stored in binary file containing a 2D torch.FloatTensor.
A plain text file contains the word vocabulary (one word per line).
```
for p in {"NP","VP","PP"}
do
  th phrases/embeddings.lua \
    -emb emb_file.bin \
    -vocab word_file.txt \
    -pfsz 400 \
    -t 10 \
    -phr $p
done
```

## do training
Training with negative sampling.
```
cd bilinear
th train.lua \
  -data "$output_dir" \
  -out "$exp_dir" \
  -pfsz 400 \
  -neg 15 \
  -lr 0.025 \
  -nbiter 100 \
  -epoch 100000 \
cd ..
```

## do inference
Given a directory containing images, it predicts the top phrases for each images.
For displaying images, users need to install the following packages: _qtlua_, _image_.
```
cd bilinear
qlua infer.lua \
  -model "$exp_dir" \
  -img "$img_dir" \
  -display
cd ..
```
