import ml_collections

import jax.numpy as jnp


def get_config():
    """Get the default hyperparameter configuration."""
    config = ml_collections.ConfigDict()

    config.mode = "train"

    # Weights & Biases
    config.wandb = wandb = ml_collections.ConfigDict()
    wandb.project = "PINN-AlievPanfilov1D"
    wandb.name = "pirate_no_res"
    wandb.tag = None

    # Physics-informed initialization
    config.use_pi_init = True
    config.pi_init_type = "initial_condition"

    # Arch
    config.arch = arch = ml_collections.ConfigDict()
    arch.arch_name = "PirateNet"
    print('running config: ', arch.arch_name)
    arch.num_layers = 3
    arch.hidden_dim = 64 #256
    arch.out_dim = 2
    arch.activation = "tanh"
    arch.periodicity = ml_collections.ConfigDict(
        {"period": (jnp.pi,), "axis": (1,), "trainable": (False,)}
    )
    arch.fourier_emb = ml_collections.ConfigDict({"embed_scale": 2, "embed_dim": 64})
    arch.nonlinearity = 0.0
    arch.reparam = ml_collections.ConfigDict(
        {"type": "weight_fact", "mean": 1.0, "stddev": 0.1}
    )
    arch.pi_init = None

    # Optim
    config.optim = optim = ml_collections.ConfigDict()
    optim.optimizer = "Adam"
    optim.beta1 = 0.9
    optim.beta2 = 0.999
    optim.eps = 1e-8
    optim.learning_rate = 1e-3
    optim.decay_rate = 0.9
    optim.decay_steps = 5000
    optim.staircase = False
    optim.warmup_steps = 5000
    optim.grad_accum_steps = 0

    # Training
    config.training = training = ml_collections.ConfigDict()
    training.max_steps = 200000
    training.batch_size_per_device = 512

    # Weighting
    config.weighting = weighting = ml_collections.ConfigDict()
    weighting.scheme = None #"ntk"
    #weighting.init_weights = ml_collections.ConfigDict({"ics": 1.0, "res": 1.0, "data": 1.0})
    weighting.init_weights = ml_collections.ConfigDict({"ics": 1.0, "data": 1.0}) # test: turn off res loss
    weighting.momentum = 0.9
    weighting.update_every_steps = 1000

    weighting.use_causal = False
    weighting.causal_tol = 1.0
    weighting.num_chunks = 32

    # Logging
    config.logging = logging = ml_collections.ConfigDict()
    logging.log_every_steps = 100
    logging.log_errors = True
    logging.log_losses = True
    logging.log_weights = True
    logging.log_nonlinearities = True
    logging.log_preds = False
    logging.log_grads = False
    logging.log_ntk = False

    # Saving
    config.saving = saving = ml_collections.ConfigDict()
    saving.save_every_steps = 10000
    saving.num_keep_ckpts = 10

    # Input shape for initializing Flax models
    config.input_dim = 3 # for 2D (t, x, y)

    # Integer for PRNG random seed.
    config.seed = 42

    return config