-- GuestService: bridge so ServingSystem can remove guests without _G.

local GuestService = {}

local removeGuestCallback: ((Instance, string) -> ())? = nil

function GuestService.setRemoveGuestCallback(callback: (Instance, string) -> ())
	removeGuestCallback = callback
end

function GuestService.removeGuestByInstance(guestInstance: Instance, reason: string)
	if removeGuestCallback then
		removeGuestCallback(guestInstance, reason)
	end
end

return GuestService
