extends Area3D

class_name Interactable

#Pas oublier de mettre box unique

#Emis quand un Interactor regarde
signal focused(interactor : Interactor)

#Emis quand un Interactor ne regarde plus
signal unfocused(interactor : Interactor)

#Emis quand un Interactor interagit
signal interacted(interactor : Interactor)

