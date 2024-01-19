#===============================================================================
# Stores and organizes the ID's of all relavent PBEffects.
#===============================================================================
# [:counter] contains effects which store a number which is counted to determine
# its value, such as the number of stacks or number of remaining turns.
# [:boolean] contains effects which are stored as either nil, true, or false.
# [:index] contains effects which store a battler index. Only relevant to
# battler effects.
#-------------------------------------------------------------------------------
$DELUXE_PBEFFECTS = {
  #-----------------------------------------------------------------------------
  # Effects that apply to the entire battlefield.
  #-----------------------------------------------------------------------------
  :field => {
    :counter => [
      :FairyLock, 
      :MudSportField,
      :WaterSportField,
      :Gravity,
      :MagicRoom, 
      :TrickRoom, 
      :WonderRoom,
      :PayDay
    ],
    :boolean => [
      :HappyHour,
      :IonDeluge
    ]
  },
  #-----------------------------------------------------------------------------
  # Effects that apply to one side of the field.
  #-----------------------------------------------------------------------------
  :team => {
    :counter => [
      :AuroraVeil,
      :LightScreen,
      :Reflect,
      :LuckyChant, 
      :Mist,  
      :Safeguard,
      :Tailwind,
      :Rainbow, 
      :Swamp, 
      :SeaOfFire,
      :Spikes, 
      :ToxicSpikes,
      :Cannonade,
      :VineLash, 
      :Volcalith, 
      :Wildfire
    ],
    :boolean => [
      :CraftyShield,
      :StealthRock,
      :Steelsurge,
      :StickyWeb
    ]
  },
  #-----------------------------------------------------------------------------
  # Effects that apply to a battler.
  #-----------------------------------------------------------------------------
  :battler => {
    :counter => [
      :Disable,
      :HealBlock,	  
      :Embargo,
      :Encore,
      :Taunt,
      :Telekinesis, 
      :ThroatChop,
      :SlowStart,
      :PerishSong,
      :Trapping,
      :Uproar,
      :Yawn,
      :Splinters,
      :Syrupy,
      :HyperBeam,
      :Outrage,
      :Rollout,
      :GlaiveRush,
      :Stockpile,
      :FuryCutter,
      :LockOn,
      :MagnetRise,
      :Charge,
      :FocusEnergy,
      :LaserFocus,
      :Substitute,
      :WeightChange,
      :Confusion	  
    ],
    :index => [
      :Attract,
      :LeechSeed,
      :MeanLook,
      :JawLock, 
      :Octolock,
      :SkyDrop
    ],
    :boolean => [
      :Flinch,
      :Transform,
      :TwoTurnAttack,
      :NoRetreat,
      :GastroAcid,
      :HelpingHand,
      :PowerTrick, 
      :Rage,
      :AquaRing,
      :Ingrain,
      :Curse,
      :Nightmare,
      :SaltCure, 
      :Foresight,
      :MiracleEye,
      :Minimize,
      :Endure,
      :Grudge,
      :DestinyBond,
      :Roost,
      :SmackDown,
      :BurnUp,
      :FlashFire,
      :TarShot, 
      :DoubleShock,
      :Electrify,
      :ExtraType,
      :MudSport,
      :WaterSport,
      :Imprison,
      :Torment,
      :MagicCoat,
      :Powder,
      :DefenseCurl
    ],
  },
  #-----------------------------------------------------------------------------
  # Effects that apply to a battler position.
  #-----------------------------------------------------------------------------
  :position => {
    :counter => [
      :Wish
    ],
    :boolean => [
      :HealingWish,
      :LunarDance,
      :ZHealing
    ]
  }
}