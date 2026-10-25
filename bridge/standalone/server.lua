if GetResourceState('es_extended') == 'started' or GetResourceState('qb-core') == 'started' then return end
error('pickle_airport requires ESX or QBCore. Standalone requires a complete custom economy/callback/permission bridge.')
