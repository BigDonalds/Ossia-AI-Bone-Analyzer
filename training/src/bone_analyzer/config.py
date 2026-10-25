"""Labels, training settings and paths shared by training, inference and the scripts."""
import os
from pathlib import Path

import torch

# --- Data ---

IMG_SIZE = 384          # letterboxed input; 384 keeps cut marks and surface detail that 224 lost
BATCH_SIZE = 32

# Windows spawns DataLoader workers by re-importing the calling script, so load in the main
# process there. Elsewhere one worker per CPU: on Colab the photo preparation, not the GPU,
# is usually what limits the speed.
NUM_WORKERS = 0 if os.name == 'nt' else (os.cpu_count() or 2)

# Most no-bone images per bone image in each training epoch. Every bone image is used once
# per epoch and up to this many no-bone images per bone image are drawn to go with them.
# There are about three bone images per no-bone image, so every no-bone image
# is used each epoch too; the detection loss is balanced so both sides count equally
# (training.trainer.BoneModelTrainer).
NO_BONE_RATIO = 1.0

# Share of training photos that get printed marks (labels, scale bars, rulers, watermarks)
# whatever their label, so printed text can't predict an answer. Without it, an earlier model read text as "bird".
PRINTED_MARKS_P = 0.35

# --- Labels ---
# Changing any list changes the model's heads and needs retraining. The app's Bones tab mirrors
# BONE_TYPES, so keep the two in step.

BONE_TYPES = [
    'skull', 'femur', 'humerus', 'rib_1_2', 'typical_rib',
    'rib_11_12', 'cervical_vertebrae', 'thoracic_vertebrae',
    'lumbar_vertebrae', 'os_coxa', 'cranium', 'tibia',
    'scapula', 'ulna', 'radius', 'mandible'
]

SPECIES_CLASSES = ['human', 'non_human']

PART_LABELS = ['complete', 'shaft', 'proximal_end', 'distal_end', 'fragment']
COMPLETENESS_LABELS = ['complete', 'fragment']
DAMAGE_LABELS = ['fracture', 'cut_marks', 'burn_signs']
# Juvenile is everything not yet skeletally mature
AGE_LABELS = ['juvenile', 'adult', 'unknown']
SEX_LABELS = ['male', 'female', 'unknown']

# Non-human bones are reported the way forensic anthropologists do: taxonomic class, then
# for mammals the family group. A family needs enough photos that actually show it to be
# learnable, so smaller families share 'other_mammal' (skunks, armadillos, opossums,
# weasels, seals...). 'rodent' is an order, grouped because rodents are common finds spread
# over many small families. Birds and reptiles stay at class level until there are enough
# photos per family. Scientific names map to these through data/taxonomy_table.json (GBIF
# backbone taxonomy), see bone_analyzer.taxonomy.
ANIMAL_CLASSES = ['mammal', 'bird', 'reptile']
MAMMAL_FAMILIES = ['canid', 'cervid', 'bovid', 'suid', 'felid', 'ursid', 'leporid', 'procyonid', 'equid',
                   'rodent', 'other_mammal']
# The family is only trained and reported on bones that show it: skulls and jaws, and
# whole limb bones, pelvis or scapula. A rib, a vertebra or a shaft splinter says little
# about the animal, and training on them teaches the photo setting instead.
FAMILY_BONE_TYPES = ('skull', 'cranium', 'mandible', 'femur', 'humerus', 'tibia', 'radius', 'ulna', 'os_coxa', 'scapula')
# A family is named only when it holds at least this share of the mammal probability; a
# weaker family guess is wrong more often than right, so the answer stays at 'mammal'.
FAMILY_MIN_CONFIDENCE = 0.5

NUM_PARTS = len(PART_LABELS)
NUM_COMPLETENESS = len(COMPLETENESS_LABELS)
NUM_DAMAGE_TYPES = len(DAMAGE_LABELS)
NUM_AGE_GROUPS = len(AGE_LABELS)
NUM_SEX = len(SEX_LABELS)
NUM_ANIMAL_CLASSES = len(ANIMAL_CLASSES)
NUM_MAMMAL_FAMILIES = len(MAMMAL_FAMILIES)

# --- Training ---

# 60-epoch runs on a smaller dataset stopped improving around epoch 28
EPOCHS = 40
LEARNING_RATE = 0.001           # heads and shared layer
BACKBONE_LR_FACTOR = 0.1        # the pretrained backbone learns at LEARNING_RATE x this
# Stop when the save score hasn't improved for this many epochs (0 or None runs all EPOCHS).
# Off: the best epochs are kept regardless, so extra epochs cost time, not quality.
EARLY_STOP_PATIENCE = 0
# Class weights and focal loss together can produce large gradients from a handful of
# rare-class images; clipping bounds the step without changing its direction. None disables it.
GRAD_CLIP_NORM = 1.0
LR_MIN = 1e-6                   # end of the cosine schedule
DEVICE = 'cuda' if torch.cuda.is_available() else 'cpu'

# When the user measures the bone (length, or widths across an end, the shaft or the
# ball/socket), re-rank species and bone type against the reference ranges in
# inference/length_reference.json (see inference/length_check.py). False keeps the
# photo-only answer and reports the measurement check alongside it.
USE_LENGTH_RERANK = True

# Focal loss, -(1 - p_t)^gamma * log(p_t), down-weights easy examples; gamma 0 is plain
# cross-entropy. Combined with class weights, gamma 2 or more can over-suppress them.
USE_FOCAL_LOSS = False
FOCAL_LOSS_GAMMA = 0.5
USE_CLASS_WEIGHTS = True

# Class weights are inverse *square root* frequency, normalised to mean 1 and clamped to
# [MIN_CLASS_WEIGHT, MAX_CLASS_WEIGHT]. Plain inverse frequency gave a one-image class a
# weight 92x that of a 237-image class, and the outlier dragged every common class onto
# the floor; the square root keeps rare classes boosted without that blow-up.
MIN_CLASS_WEIGHT = 0.2
MAX_CLASS_WEIGHT = 4.0
# A class with fewer than this many training images can't be learned from, and weighting
# it up only distorts the rest, so it is left at weight 1.0.
MIN_CLASS_IMAGES = 3
# Damage marks are rare next to the explicit "no" labels (cuts ~1 in 10, fractures and burns
# far fewer). Each mark's positives are weighted by sqrt(negatives / positives), the same
# square-root rule as the class weights, capped so a couple of dozen burns can't dominate.
MAX_DAMAGE_POS_WEIGHT = 6.0

# Each head's loss is multiplied by its weight before summing. Class weights already handle
# imbalance inside a head, so these only balance heads against each other. Heads with few
# labelled images (age, sex, damage) are kept modest: large weights on a handful of labels
# make the shared backbone memorise them.
LOSS_TASK_WEIGHTS = {
    'bone_detection': 1.0,
    'species': 2.0,
    'bone_type': 3.0,           # 16 classes and the weakest of the main heads
    'animal_class': 1.0,        # mammal / bird / reptile: easy, many images
    'animal_family': 2.0,
    'bone_part': 0.5,           # mostly "complete"
    'completeness': 0.5,        # mostly "complete"
    'damage': 1.0,              # positives are rare next to the explicit "no" labels
    'age_group': 1.0,           # human images with an assessed age only
    'sex': 1.0,                 # human images with an assessed sex only
}

# --- Choosing the saved model ---

# Save score: weighted average of these validation metrics. A metric whose head has no
# labelled validation images is left out.
SAVE_WEIGHTS = {
    'bone_accuracy': 3.0,            # bone vs no-bone, balanced over both classes
    'species_f1': 3.0,
    'human_found_rate': 3.0,         # missing a human bone is the costliest mistake
    'bone_type_f1': 4.0,             # weighted by each type's image count
    'animal_class_f1': 1.0,
    'animal_family_f1': 2.5,
    'part_accuracy': 0.2,
    'completeness_accuracy': 0.2,
    # damage_accuracy: left out, nearly every assessed bone is undamaged so it sits at ~97%.
    # age_accuracy, sex_accuracy: left out, measured on ~35 and ~19 validation images, so two
    # photos swing them 6-10 points and they ended up choosing checkpoints. Still trained and printed.
}
# F1 rather than each class's hit rate (balanced accuracy): a hit rate only
# counts what a class found, never what it wrongly claimed. With 58 validation birds and 519
# mammals, one more bird found outweighed nine mammals called bird, so the score rewarded
# over-calling the rare classes. Bone type F1 is weighted by image count because several types
# have 2-5 validation images, which would make an unweighted average jump around.

# Rates of the mistakes that send a user the wrong way, subtracted from the save score times
# these weights. At 4, a 5% rate costs about 1 point.
SAVE_PENALTIES = {
    'no_bone_called_bone_rate': 4.0,
    'animal_called_human_rate': 4.0,
    'mammal_called_bird_rate': 4.0,
}

# The final model averages the weights of the AVERAGE_TOP_K best-scoring epochs from the
# second half of training. Neighbouring epochs' scores differ by about as much as the score
# wobbles between epochs (half a point), so the single best is partly luck. If the average
# scores more than AVERAGE_TOLERANCE below the best single epoch, that epoch is kept instead;
# the best score was the highest of dozens of noisy ones, so it reads a little high. When the
# average is kept, the best single epoch is saved next to it (training.trainer.best_epoch_path)
# and both are scored on the test set. 1 turns averaging off.
AVERAGE_TOP_K = 5
AVERAGE_FROM = 0.5               # only epochs from this share of the run onwards are candidates
AVERAGE_TOLERANCE = 0.005

# --- Paths ---

PROJECT_DIR = Path(__file__).resolve().parents[2]
DATA_DIR = PROJECT_DIR / 'data'
TAXONOMY_TABLE = DATA_DIR / 'taxonomy_table.json'
RAW_DIR = DATA_DIR / 'raw'

# On Colab with Drive mounted, checkpoints, the unfinished-run folder and the training logs go
# to Drive so they outlive the session, while images are read from Colab's local disk, which
# is far faster than reading through Drive.
COLAB_DRIVE = Path('/content/drive/MyDrive')
CHECKPOINT_DIR = (COLAB_DRIVE / 'bone_analyzer' / 'checkpoints' if COLAB_DRIVE.is_dir()
                  else PROJECT_DIR / 'checkpoints')
LOG_DIR = CHECKPOINT_DIR.parent / 'logs'    # copies of the training runs' terminal output, for debugging


def images_dir(data_dir=DATA_DIR):
    """Folder that annotation image_path values are relative to."""
    return Path(data_dir) / 'images'


def annotation_file(split, no_bone=False, data_dir=DATA_DIR):
    return Path(data_dir) / 'annotations' / (f'{split}_no_bone.json' if no_bone else f'{split}.json')


IMAGES_DIR = images_dir()
