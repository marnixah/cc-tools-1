--#import "const.lua"
--#import "util.lua"
--#import "ipmc/client.lua"
--#import "ipmc/packets.lua"

local modems = {}
for i, v in ipairs(rs.getSides()) do
    if peripheral.getType(v) == "modem" then
        modems[v] = peripheral.wrap(v)
    end
end
local _connected = false

settings.load(".frednet-client")

local packet_handlers = {
    [CHANNEL_IP] = ipmc_handle_packet
}

local function _open_modem(m)
    for s, channel in pairs(ALL_CHANNELS) do
        m.open(channel)
    end
end

--[[
    Connect to frednet.

    Returns a thread representing the running event loop.
    A running event loop will generate "frednet_message" events for received messages.
]]
function connect (side)
    if side == nil then
        for s, modem in pairs(modems) do
            _open_modem(modem)
        end
    else
        local t = peripheral.getType(side)
        assert(t == "modem", "Expected peripheral of type 'modem' on side " .. side .. " but was " .. t)
        _open_modem(peripheral.wrap(side))
    end
    _connected = true
    return libfredio.async(function ()
        while _connected do
            local event, side, ch_d, ch_s, msg, dist = os.pullEvent("modem_message") 
            h = packet_handlers[ch_d]
            if h ~= nil then
                h(msg)
            end
        end
        print("exiting frednet event loop")
    end)()

end

--[[
    Disconnect from frednet.

    Closes all channels on all modems connected to this computer.
]]
function disconnect ()
    _connected = false
    for i, modem in ipairs(modems) do
        modem.closeAll()
    end
end

function is_connected() 
    return _connected
end


--[[
    Transmit a data packet to another computer.
    Optional argument side specifies the interface to be used.
]]
function transmit(dst_addr, dst_port, src_port, data, side)
    return transmit_routed(dst_addr, dst_port, ip2num(settings.get("frednet.ip")), src_port, data, side)
end

function transmit_routed(dst_addr, dst_port, src_addr, src_port, data, side)
    assert(_connected, "Not connected to frednet.")
    local p = IpPacket(src_addr, src_port, dst_addr, dst_port, data)
    if side == nil then
        for s, modem in pairs(modems) do
            if modem.isOpen(CHANNEL_IP) then
                modem.transmit(CHANNEL_IP, CHANNEL_IP, p)
            end
        end
    else
        assert(modems[side] ~= nil, "Tried sending packet via interface on side " .. side .. " but no modem was found.")
        modems[side].transmit(CHANNEL_IP, CHANNEL_IP, p)
    end
end