import api from "./config.js"

export const get_images = async () => {
    try {
        const images = await api.get("/api/images")
        return images.data
    } catch (e) {
        return e.response?.data?.message || "error at imagecalls.js/get_images without message"
    }
}