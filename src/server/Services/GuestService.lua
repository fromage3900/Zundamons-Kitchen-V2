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
	-- GuestManager owns bookkeeping and presentation cleanup when its callback is
	-- available. Destruction remains guaranteed here so serving cannot leave a
	-- settled, non-interactive guest in the world during bootstrap/order faults.
	if guestInstance.Parent then
		guestInstance:Destroy()
	end
end

return GuestService
