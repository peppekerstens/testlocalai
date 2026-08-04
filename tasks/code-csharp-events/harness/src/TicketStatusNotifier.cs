using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Bench.Events
{
    public delegate void StatusChangedHandler(string ticketId, string oldStatus, string newStatus);

    public sealed class TicketStatusNotifier
    {
        public event StatusChangedHandler? StatusChanged;

        public void Publish(string ticketId, string oldStatus, string newStatus)
        {
            if (StatusChanged == null)
                return;

            var exceptions = new List<Exception>();
            foreach (var d in StatusChanged?.GetInvocationList() ?? Array.Empty<Delegate>())
            {
                try
                {
                    ((StatusChangedHandler)d)(ticketId, oldStatus, newStatus);
                }
                catch (Exception ex)
                {
                    exceptions.Add(ex);
                }
            }

            if (exceptions.Count > 0)
                throw new AggregateException(exceptions);
        }
    }
}
