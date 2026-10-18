import { useEffect } from "react";

// Shared dialog shell: closes on Escape or a click on the backdrop.
export default function Modal({ title, titleId, onClose, onSubmit, children }) {
  useEffect(() => {
    const onKeyDown = (event) => event.key === "Escape" && onClose();
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [onClose]);

  return (
    <div className="modal-backdrop" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
      <form className="modal" role="dialog" aria-modal="true" aria-labelledby={titleId} onSubmit={onSubmit}>
        <h2 id={titleId}>{title}</h2>
        {children}
      </form>
    </div>
  );
}
