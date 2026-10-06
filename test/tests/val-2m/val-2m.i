# val-2m: H2 pumping through a dense BCY20 film with charge conservation and Butler-Volmer kinetics (Lee et al., Solid State Ionics 176, 2005)
#
# Domain: 1D dense electrolyte, x = 0 (positrode/electrolyte interface) to x = L (negatrode/electrolyte interface)
#   positrode (x = 0, boundary 'left'):  80% H2, 3% H2O; Phi_ed = V_app; H2 + 2 O_O^x -> 2 OH_O^. + 2 e'
#   negatrode (x = L, boundary 'right'): wet N2 sweep, 3% H2O; Phi_ed = 0; reverse reaction releases H2
#
# Unknowns:
#   c_OT   [at/nm^3]  proton concentration OH_O^. ("OT" = TMAP8 tritium naming)
#   c_V    [at/nm^3]  oxygen vacancy concentration V_O^..
#   phi_el [V]        electrostatic potential of the electrolyte phase
#   Lattice oxygen O_O^x is not solved; it is 3N - c_V (N = formula units per nm^3).
#
# Equations: Nernst-Planck for c_OT (z = 1) and c_V (z = 2), charge continuity div(J_OT + 2 J_V) = 0 for phi_el.
# Face reactions: Butler-Volmer charge transfer (rate_CT) and hydration H2O + V + O_O^x <-> 2 OH (rate_hydration).
# Naming: _po/_ne = positrode/negatrode face; mig_k = z_k F D_k c_k / (R T) (migration coefficient, not a conductivity).
# Units: nm, s, at/nm^3, J/mol, V; gas pressures normalized by 1 atm.

# Physical constants
R = '${units 8.31446261815324 J/mol/K}' # ideal gas constant based on number used in include/utils/PhysicalConstants.h
N_a = '${units 6.02214076e23 at/mol}' # ideal gas constant based on number used in include/utils/PhysicalConstants.h
q = '${units 1.602176634e-19 C}' # quantity of charge
F = '${fparse N_a * q}'

# thermal parameters
temperature_initial = '${units 773 K}' # 500C

# Model parameters
endtime = '1e5'
dt_max = '2e3'
dt_start_charging = '${units 1e-5 s}'

# Geometry and mesh
length = '${units 10 mum -> nm}' # BCY20
num_nodes = 300

# Material properties
density_BCY20 = '${units ${fparse 1.0 * 6.154} g/cm^3 -> g/m^3}'
molar_mass_BCY20 = '${units 283.42 g/mol}'
N = '${units ${fparse density_BCY20 / molar_mass_BCY20 * N_a} at/m^3 -> at/nm^3}' # 1.3076089986e10

# Initial concentrations
OT_concentration_initial = 1e-5
hydration_limit_S = 0.2
oxygen_vacancy_concentration_initial = '${units ${fparse hydration_limit_S / 2 * N} at/nm^3}'

# Gas compositions at each electrode (partial pressure / 1 atm)
p_H2_po_value = 0.8     # positrode: 80% H2, 3% H2O, balance He
p_H2O_po_value = 0.03
p_H2O_ne_value = 0.03
A_cell = 1.1            # cm^2, Lee cathode area (1.1 at 500/600 C, 0.97 at 700 C)
sweep_flow = 150        # sccm, negatrode wet N2 sweep
p_H2_bg = 1e-6          # background H2 at negatrode (permeation/leak), estimate; Lee: < ~7e-6 at 500-700 C

# chemical_reaction - optimized parameters used for val-2l no-Joule validation
dH_hyd = '${units -1.54415211e+05 J/mol}'
dS_hyd = '${units -1.67187585e+02 J/mol/K}'
kf_hyd_mol_exponent = -1.19792592e+01
ramp_time = 1
kf_hyd_mol = '${units ${fparse 8.0 * 10 ^ kf_hyd_mol_exponent} m^4/mol/s}'
kf_hyd_value = '${units ${fparse kf_hyd_mol / N_a} m^4/at/s -> nm^4/at/s}'
kf_hyd_energy = '${units -7.31595474e+03 J/mol}'
diffusivity_OT_prefactor_exponent = -1.26000119e+01
diffusivity_OT_prefactor = '${units ${fparse 2.03 * 10 ^ diffusivity_OT_prefactor_exponent} m^2/s -> nm^2/s}'
diffusivity_OT_energy = '${units 8.65880079e+03 J/mol}'
diffusivity_V_O_prefactor_exponent = -5.33084375e+00
diffusivity_V_O_prefactor = '${units ${fparse 1.1 * 10 ^ diffusivity_V_O_prefactor_exponent} m^2/s -> nm^2/s}'
diffusivity_V_O_energy = '${units 5.87658926e+04 J/mol}'

# voltage
V_current = 2.0 # CONSTANT_VOLTAGE - no ${units} wrapper so CLI override works
V_ramp_time = 10        # s, positrode potential ramps from 0 to V_current at start-up

# charge transfer (BV, multiplied-out form) - Placeholder values, to be calibrated
k_CT = 1e4          # nm/s
E_CT = 0            # J/mol
beta_a = 0.5
p_star = 1.0        # normalized by p_atm; set to 1e10 to switch off adsorption term

# target flux for error computation (overridden by parent via cli_args)

[Mesh]
  [cmg]
    type = CartesianMeshGenerator
    dim = 1
    dx = '${fparse length}'
    ix = '${fparse num_nodes}'
    subdomain_id = '0'
  []
[]

[Variables]
  #### Dry variable
  [c_OT] # (atoms/nm^3)
    initial_condition = ${OT_concentration_initial}
  []
  [c_V]
    initial_condition = ${oxygen_vacancy_concentration_initial}
  []
  [phi_el]
    initial_condition = 0
  []
[]

[AuxVariables]
  [temperature]
    initial_condition = ${temperature_initial}
  []
  #### Dry auxvariable
[]


[AuxKernels]
  [temperature_Aux]
    type = FunctionAux
    variable = temperature
    function = Temperature_function
  []

  #### Dry auxkernels


[]

[Problem]
  type = ReferenceResidualProblem
  extra_tag_vectors = 'ref'
  reference_vector = 'ref'
[]

[Kernels]
  #### Dry kernels
  [time_OT]
    type = ADTimeDerivative
    variable = c_OT
    extra_vector_tags = ref
  []
  [diffusion_OT]
    type = ADMatDiffusion
    variable = c_OT
    diffusivity = D_OT
    extra_vector_tags = ref
  []
  [time_V]
    type = ADTimeDerivative
    variable = c_V
    extra_vector_tags = ref
  []
  [diffusion_V]
    type = ADMatDiffusion
    variable = c_V
    diffusivity = D_V
    extra_vector_tags = ref
  []
  # voltage for OH
  [migration_OT]
    type = ADMatDiffusion
    variable = c_OT
    v = phi_el
    diffusivity = mig_OT
    extra_vector_tags = ref
  []
  # voltage for V_O
  [migration_V]
    type = ADMatDiffusion
    variable = c_V
    v = phi_el
    diffusivity = mig_V
    extra_vector_tags = ref
  []
    # charge continuity for phi_el
  [charge_migration]
    type = ADMatDiffusion
    variable = phi_el
    diffusivity = mig_total
    extra_vector_tags = ref
  []
  [charge_diffusion_OT]
    type = ADMatDiffusion
    variable = phi_el
    v = c_OT
    diffusivity = D_OT
    extra_vector_tags = ref
  []
  [charge_diffusion_V]
    type = ADMatDiffusion
    variable = phi_el
    v = c_V
    diffusivity = D_V_x2
    extra_vector_tags = ref
  []
[]

[BCs]
  #### Dry BCs
  [OT_po]
    type = ADMatNeumannBC
    variable = c_OT
    boundary = left
    value = 1
    boundary_material = flux_OT_in
  []
  [V_po]
    type = ADMatNeumannBC
    variable = c_V
    boundary = left
    value = 1
    boundary_material = flux_V_in
  []
  [OT_ne]
    type = ADMatNeumannBC
    variable = c_OT
    boundary = right
    value = 1
    boundary_material = flux_OT_in
  []
  [V_ne]
    type = ADMatNeumannBC
    variable = c_V
    boundary = right
    value = 1
    boundary_material = flux_V_in
  []

  [charge_po]
    type = ADMatNeumannBC
    variable = phi_el
    boundary = left
    value = 1
    boundary_material = flux_charge_in
  []

  [charge_ne]
    type = ADMatNeumannBC
    variable = phi_el
    boundary = right
    value = 1
    boundary_material = flux_charge_in
  []
[]

[Functions]
  [Temperature_function]
    type = ParsedFunction
    expression = '${temperature_initial}'
  []
  [ramp]
    type = ParsedFunction
    expression = 'min(t / ${ramp_time}, 1.0)'
  []
  [ramp_V]
    type = ParsedFunction
    expression = 'min(t / ${V_ramp_time}, 1.0)'
  []
[]

[Materials]
  [D_OT]
    type = ADParsedMaterial
    property_name = 'D_OT'
    coupled_variables = 'temperature'
    expression = '${diffusivity_OT_prefactor} * exp(-${diffusivity_OT_energy} / ${R} / temperature)'
  []
  [D_V]
    type = ADParsedMaterial
    property_name = 'D_V'
    coupled_variables = 'temperature'
    expression = '${diffusivity_V_O_prefactor} * exp(-${diffusivity_V_O_energy} / ${R} / temperature)'
  []
  [mig_OT]
    type = ADParsedMaterial
    property_name = 'mig_OT'
    coupled_variables = 'c_OT temperature'
    material_property_names = 'D_OT'
    expression = 'D_OT * ${F} * c_OT / ${R} / temperature'
  []
  [mig_V]
    type = ADParsedMaterial
    property_name = 'mig_V'
    coupled_variables = 'c_V temperature'
    material_property_names = 'D_V'
    expression = '2 * D_V * ${F} * c_V / ${R} / temperature'
  []

  [K_hyd]
    type = ADParsedMaterial
    property_name = 'K_hyd'
    coupled_variables = 'temperature'
    expression = 'exp( ( ${dH_hyd} - temperature * ${dS_hyd}) / ${R} / temperature )'
  []
  [kf_hyd]
    type = ADParsedMaterial
    property_name = 'kf_hyd'
    coupled_variables = 'temperature'
    expression = '${kf_hyd_value} * exp(-${kf_hyd_energy} / ${R} / temperature)'
  []
  [kb_hyd]
    type = ADParsedMaterial
    property_name = 'kb_hyd'
    material_property_names = 'kf_hyd K_hyd'
    expression = 'kf_hyd / K_hyd'
  []


  [flux_OT_in] # protons into film: charge transfer + hydration
    type = ADParsedMaterial
    boundary = 'left right'
    property_name = 'flux_OT_in'
    material_property_names = 'rate_CT rate_hydration'
    expression = 'rate_CT + 2 * rate_hydration'
  []
  [flux_H2_out] # H2 released, positive = out of film
    type = ADParsedMaterial
    boundary = 'left right'
    property_name = 'flux_H2_out'
    material_property_names = 'rate_CT'
    expression = '-0.5 * rate_CT'
  []
  [flux_charge_in] # current into film / F
    type = ADParsedMaterial
    boundary = 'left right'
    property_name = 'flux_charge_in'
    material_property_names = 'rate_CT'
    expression = 'rate_CT'
  []
  [flux_V_in] # V_O
    boundary = 'left right'
    type = ADDerivativeParsedMaterial
    property_name = 'flux_V_in'
    material_property_names = 'rate_hydration'
    expression = '-1 * rate_hydration'
  []
  [flux_H2O_out] # T2O
    boundary = 'left right'
    type = ADDerivativeParsedMaterial
    property_name = 'flux_H2O_out'
    material_property_names = 'rate_hydration'
    expression = '-1 * rate_hydration'
  []

  [mig_total]
    type = ADParsedMaterial
    property_name = 'mig_total'
    material_property_names = 'mig_OT mig_V'
    expression = 'mig_OT + 2 * mig_V'
  []

  [D_V_x2]
    type = ADParsedMaterial
    property_name = 'D_V_x2'
    material_property_names = 'D_V'
    expression = '2 * D_V'
  []



  [rate_CT_po] # H2 + 2 O_O -> 2 OH_O + 2 e'(ed), per proton, at/nm^2/s ; Phi_ed = V_app
    type = ADParsedMaterial
    boundary = left
    property_name = 'rate_CT'
    coupled_variables = 'c_OT c_V phi_el temperature'
    postprocessor_names = 'p_H2_po V_po'
    expression = '${k_CT} * exp(-${E_CT} / ${R} / temperature) / (1 + sqrt(p_H2_po / ${p_star}))
                  * ( sqrt(p_H2_po) * (3 * ${N} - c_V)
                      * exp(${beta_a} * ${F} / ${R} / temperature * (V_po - phi_el))
                    - c_OT
                      * exp(-(1 - ${beta_a}) * ${F} / ${R} / temperature * (V_po - phi_el)) )'
  []
  [rate_CT_ne] # same reaction ; Phi_ed = 0
    type = ADParsedMaterial
    boundary = right
    property_name = 'rate_CT'
    coupled_variables = 'c_OT c_V phi_el temperature'
    postprocessor_names = 'p_H2_ne'
    expression = '${k_CT} * exp(-${E_CT} / ${R} / temperature) / (1 + sqrt(p_H2_ne / ${p_star}))
                  * ( sqrt(p_H2_ne) * (3 * ${N} - c_V)
                      * exp(${beta_a} * ${F} / ${R} / temperature * (0 - phi_el))
                    - c_OT
                      * exp(-(1 - ${beta_a}) * ${F} / ${R} / temperature * (0 - phi_el)) )'
  []
  [rate_hydration_po] # H2O + V_O + O_O -> 2 OH_O, at/nm^2/s
    type = ADParsedMaterial
    boundary = left
    property_name = 'rate_hydration'
    coupled_variables = 'c_OT c_V'
    postprocessor_names = 'p_H2O_po'
    material_property_names = 'kf_hyd kb_hyd'
    expression = 'kf_hyd * p_H2O_po * (3 * ${N} - c_V) * c_V - kb_hyd * c_OT^2'
  []
  [rate_hydration_ne] # H2O + V_O + O_O -> 2 OH_O, at/nm^2/s
    type = ADParsedMaterial
    boundary = right
    property_name = 'rate_hydration'
    coupled_variables = 'c_OT c_V'
    postprocessor_names = 'p_H2O_ne'
    material_property_names = 'kf_hyd kb_hyd'
    expression = 'kf_hyd * p_H2O_ne * (3 * ${N} - c_V) * c_V - kb_hyd * c_OT^2'
  []
[]

[Postprocessors]
  #### Postprocessors for flux under dry
  [H2_flux_po]
    type = ADSideAverageMaterialProperty
    boundary = left
    property = flux_H2_out
    execute_on = 'INITIAL TIMESTEP_END'
    outputs = 'console csv'
  []
  [H2O_flux_po]
    type = ADSideAverageMaterialProperty
    boundary = left
    property = flux_H2O_out
    execute_on = 'INITIAL TIMESTEP_END'
    outputs = 'console csv'
  []
  [OT_flux_po]
    type = ADSideAverageMaterialProperty
    boundary = left
    property = flux_OT_in
    execute_on = 'INITIAL TIMESTEP_END'
    outputs = 'console csv'
  []
  [OT_flux_ne]
    type = ADSideAverageMaterialProperty
    boundary = right
    property = flux_OT_in
    execute_on = 'INITIAL TIMESTEP_END'
    outputs = 'console csv'
  []
  [H2O_flux_ne]
    type = ADSideAverageMaterialProperty
    boundary = right
    property = flux_H2O_out
    execute_on = 'INITIAL TIMESTEP_END'
    outputs = 'console csv'
  []
  [H2_flux_ne]
    type = ADSideAverageMaterialProperty
    boundary = right
    property = flux_H2_out
    execute_on = 'INITIAL TIMESTEP_END'
    outputs = 'console csv'
  []

  # necessary parameters
  [K_hyd_average]
    type = ADElementAverageMaterialProperty
    mat_prop = K_hyd
  []
  [kf_hyd_average]
    type = ADElementAverageMaterialProperty
    mat_prop = kf_hyd
  []
  [kb_hyd_average]
    type = ADElementAverageMaterialProperty
    mat_prop = kb_hyd
  []
  [D_OT_average]
    type = ADElementAverageMaterialProperty
    mat_prop = D_OT
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [D_V_average]
    type = ADElementAverageMaterialProperty
    mat_prop = D_V
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [temperature_average]
    type = ElementAverageValue
    variable = temperature
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [voltage_value]
    type = ParsedPostprocessor
    expression = ${V_current}
    execute_on = 'INITIAL TIMESTEP_END'
  []

  [r_CT_po]
    type = ADSideAverageMaterialProperty
    boundary = left
    property = rate_CT
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [r_CT_ne]
    type = ADSideAverageMaterialProperty
    boundary = right
    property = rate_CT
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [current_density_po_A_cm2]   # 1 at/nm^2/s = 1.602e-5 A/cm^2
    type = ParsedPostprocessor
    pp_names = 'r_CT_po'
    expression = 'r_CT_po * 1.602176634e-5'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [current_density_ne_A_cm2]
    type = ParsedPostprocessor
    pp_names = 'r_CT_ne'
    expression = '-r_CT_ne * 1.602176634e-5'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [charge_balance_rel_error]      # should go to ~0 at steady state
    type = ParsedPostprocessor
    pp_names = 'r_CT_po r_CT_ne'
    expression = 'abs(r_CT_po + r_CT_ne) / (abs(r_CT_po) + 1e-30)'
    execute_on = 'INITIAL TIMESTEP_END'
  []

  [c_OT_po]
    type = PointValue
    variable = c_OT
    point = '0 0 0'
  []
  [c_OT_ne]
    type = PointValue
    variable = c_OT
    point = '${length} 0 0'
  []
  [c_V_po]
    type = PointValue
    variable = c_V
    point = '0 0 0'
  []
  [c_V_ne]
    type = PointValue
    variable = c_V
    point = '${length} 0 0'
  []
  [phi_el_po]
    type = PointValue
    variable = phi_el
    point = '0 0 0'
  []
  [phi_el_ne]
    type = PointValue
    variable = phi_el
    point = '${length} 0 0'
  []
  [c_OT_inventory]
    type = ElementIntegralVariablePostprocessor
    variable = c_OT
  []
  [c_V_inventory]
    type = ElementIntegralVariablePostprocessor
    variable = c_V
  []
  [p_H2_po]
    type = FunctionValuePostprocessor
    function = ramp
    scale_factor = ${p_H2_po_value}
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [p_H2O_po]
    type = FunctionValuePostprocessor
    function = ramp
    scale_factor = ${p_H2O_po_value}
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [p_H2O_ne]
    type = FunctionValuePostprocessor
    function = ramp
    scale_factor = ${p_H2O_ne_value}
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [p_H2_ne] # background + produced H2 / (sweep + produced H2), well-mixed negatrode chamber
    type = ParsedPostprocessor
    pp_names = 'H2_flux_ne'
    expression = '${p_H2_bg} + max(H2_flux_ne, 0) * ${A_cell} * 1e14 / ${N_a} / (${sweep_flow} / 22414 / 60 + max(H2_flux_ne, 0) * ${A_cell} * 1e14 / ${N_a})'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [V_po] # positrode electrode potential, ramped from 0 to V_current
    type = FunctionValuePostprocessor
    function = ramp_V
    scale_factor = ${V_current}
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
[]

[Controls]
  [stochastic]
    type = SamplerReceiver
  []
[]

[Executioner]
  type = Transient
  scheme = implicit-euler
  solve_type = NEWTON
  petsc_options_iname = '-pc_type -snes_type'
  #petsc_options_value = 'lu vinewtonrsls'
  petsc_options_value = 'lu newtonls'
  nl_rel_tol = 5e-6
  nl_abs_tol = 1e-12
  end_time = ${endtime}
  automatic_scaling = true
  compute_scaling_once = true
  line_search = none
  error_on_dtmin = false  # must stay false for ignore_solve_not_converge to work in Level 2
  abort_on_solve_fail = true  # fast-fail on first NL divergence; prevents stutter at dtmin
  dtmin = 1e-10
  nl_max_its = 20
  dtmax = ${dt_max}
  [TimeStepper]
    type = IterationAdaptiveDT
    dt = ${dt_start_charging}
    optimal_iterations = 15
    growth_factor = 2.0
    cutback_factor = 0.5
    cutback_factor_at_failure = 0.5
  []
[]

[Debug]
  show_var_residual_norms = true
[]

[Outputs]
  exodus = false
  [csv]
    type = CSV
  []
  # [exodus]
  #   type = Exodus
  # []
[]
