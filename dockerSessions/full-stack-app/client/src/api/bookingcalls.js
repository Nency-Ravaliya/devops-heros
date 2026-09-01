import api from "./config.js";

export const post_booking = async (body) => {
    try {
        const response = await api.post("/api/bookings", body)
        return response
    } catch (e) {
        return e.response?.data?.message || "error at eventcalls.js/get_events without message"
    }
}