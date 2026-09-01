import { Link } from "react-router-dom";
import { AiFillHome } from "react-icons/ai";

export default function RedirectHome() {
  return (
    <Link
      to="/home"
      className="fixed top-4 left-4 text-green-700 text-3xl hover:text-green-900 transition-colors"
    >
      <AiFillHome />
    </Link>
  );
}
